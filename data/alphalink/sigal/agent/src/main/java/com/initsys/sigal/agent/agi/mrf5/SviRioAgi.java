package com.initsys.sigal.agent.agi.mrf5;

import java.util.concurrent.TimeoutException;

import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.Locale;
import java.util.Date;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiHangupException;
import org.asteriskjava.fastagi.AgiRequest;
import org.asteriskjava.live.HangupCause;

import com.initsys.sigal.numbers.PhoneNumberUtils;

import com.initsys.sigal.agent.SiAgentTemplate;

import com.initsys.sigal.agent.agi.IdentityException;
import com.initsys.sigal.agent.agi.LimitReachedException;
import com.initsys.sigal.agent.agi.IncomingAccountException;
import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.agent.agi.SipHeaderIcidExtractor;

import com.initsys.sigal.protocol.Si.SviRioQueryResponse;
import com.initsys.sigal.protocol.Si.SmsServerAck;

import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;

import com.initsys.sigal.vno.VnoConstants;

import static org.apache.commons.lang.StringUtils.defaultString;
import static org.apache.commons.lang.StringUtils.stripStart;
import static org.apache.commons.lang.StringUtils.stripEnd;
import static org.apache.commons.lang.StringUtils.isBlank;
import static org.apache.commons.lang.StringUtils.defaultString;

// TODO: gestion correcte du redirect entrant
public class SviRioAgi extends AbstractMrf5Agi {
  /** logger */
  static final Logger log = LoggerFactory.getLogger(SviRioAgi.class);

  private String inboundGwChannelName;

  private SiAgentTemplate sviRioTemplate;

  public String getInboundGwChannelName() {
    return inboundGwChannelName;
  }

  public void setInboundGwChannelName(String inboundGwChannelName) {
    this.inboundGwChannelName = inboundGwChannelName;
  }

  public SiAgentTemplate getSviRioTemplate() {
    return sviRioTemplate;
  }

  public void setSviRioTemplate(SiAgentTemplate template) {
    this.sviRioTemplate = template;
  }

  protected String getIcid(AgiChannel channel) {
    try {
      return new SipHeaderIcidExtractor().getIcid(channel);
    } catch (IllegalStateException e) {
      // TODO: transitional block: no ICID was found we create a
      // transational one.
      String icid = "t-" + createIcid();
      log
        .warn("P-Charging-Vector (or ICID variable) was not found. Generating a transitional one: "
            + icid);
      return icid;
    }
  }

  private void sleep(long duration) {
    try {
      Thread.sleep(duration);
    } catch (InterruptedException e) {
      log.error("InterruptedException occured ");
    } catch (IllegalMonitorStateException e) {
      log.error("IllegalMonitorStateException occured ");
    }      
  }

  @Override
  public void handleCall(AgiRequest request, AgiChannel channel,
      CallContext callContext) throws AgiException, TimeoutException {
    LidbQueryResponse lidbResponse = getTemplate().queryLineInfoByNumber(
        callContext.getCalledNumber());

    if (ResponseStatusCode.NOT_FOUND == lidbResponse.getStatus().getCode()) {
      throw new IncomingAccountException("Unable to find LIDB account for '"
          + callContext.getCalledNumber() + "'");
    }

    String identityValue = defaultString(channel
        .getVariable("SIP_HEADER(P-Asserted-Identity)"));
    boolean privacy = defaultString(
        channel.getVariable("SIP_HEADER(Privacy)")).equals("id");

    // gestion de l'identite
    identityValue = stripEnd(stripStart(identityValue, "<tel:+"), ">");
    if(isBlank(identityValue)) {
      throw new IdentityException("Missing identity value");
    }
    callContext.setCallingIdentityNumber(identityValue);
    callContext.setPrivacy(privacy);
    getCallNormalizer().normalizeOutbound(callContext,
        lidbResponse.getOutboundNumberingPlan());

    if (!checkCounters(lidbResponse, false)) {
      // Unreachable block due to checkCounters implementation
      throw new LimitReachedException("Limit reached : a counter has reached its max value");
    }

    boolean loop = true;
    SviRioQueryResponse sviRioResponse = null; 
    channel.answer();
    sleep(2000);

    // Case : No response for the SVI.RIO.REQUEST 
    try { 
      sviRioResponse = getSviRioTemplate().querySviRioByNumber(
          callContext.getCallingIdentityNumber());
    } catch (TimeoutException e) {
      log.error("Timeout exception has occured : No response for the SVI.RIO.QUERY.REQUEST ");
      try {
        do {
          if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/unavailable", "8") == '8') {
            continue;
          }
          if (channel.waitForDigit(3000) != '8') {
            loop = false;
          }
        } while (loop);
      } catch (AgiHangupException hangupException) {
        if (log.isDebugEnabled()) {
          log.error(hangupException.getMessage(), hangupException);
        }
        log.error(hangupException.getMessage());
      }
      throw e;
    } catch (RuntimeException e) {
      log.error("JMS exception has occured : " + e.getMessage() );
      try {
        do {
          if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/unavailable", "8") == '8') {
            continue;
          }
          if (channel.waitForDigit(3000) != '8') {
            loop = false;
          }
        } while (loop);
      } catch (AgiHangupException hangupException) {
        if (log.isDebugEnabled()) {
          log.error(hangupException.getMessage(), hangupException);
        }
        log.error(hangupException.getMessage());
      }
      throw e;
    }
    sendInitialCdr(callContext);
    Date theDate = null;

    // Send SMS when allowed (The third alphanumeric character of RIO is "P" not "E")
    try {
      if (sviRioResponse.hasMsisdn() && sviRioResponse.hasRio()
          && (sviRioResponse.getRio().charAt(2) == 'P'))  {
        SmsServerAck smsResponse = getSviRioTemplate().sendRioBySms(
            sviRioResponse);
        if (smsResponse.hasStatus() && smsResponse.getStatus() != 200) {
          log.error("Sms server response : " + smsResponse.getStatus()
              + " : " + smsResponse.getMessage());
        }
          }
    } catch (TimeoutException e) {
      log.error("Timeout exception has occured : No response for the SMS.SEND.REQUEST ");
    }
    /* Useless : see below */
    /* try { */
    do {

      // msisdn, RIO and date exist
      if (sviRioResponse.hasMsisdn() &&
          sviRioResponse.hasRio() &&
          (sviRioResponse.getRio().charAt(2) == 'P'))  {
        if (sviRioResponse.hasDate()) {
          SimpleDateFormat ISO8601DATEFORMAT = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", Locale.FRANCE);
          try {
            theDate = ISO8601DATEFORMAT.parse(sviRioResponse.getDate().replaceAll(":00$", "00"));
          } catch (ParseException e) {
            log.error("Parse exception has occured ");
          }
          if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/welcome_date", "8") == '8') {
            continue;
          }
          if (channel.sayDateTime(theDate.getTime()/1000L, "8", "dBY") == '8') {
            continue;
          }
          if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/rio_is", "8") == '8') {
            continue;
          }
        } else { 

          //msisdn and RIO exists but no date associated
          if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/welcome_no_date", "8") == '8') {
            continue;
          }
        }    
        if (channel.sayAlpha(sviRioResponse.getRio(), "8") == '8') {
          continue;
        }
        if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/sms", "8") == '8') {
          continue;
        }
      } else {

        //RIO exist but the line's type is "Entreprise"
        if (sviRioResponse.hasRio() && 
            sviRioResponse.getRio().charAt(2) == 'E') {
          if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/entreprise", "8") == '8') {
            continue;
          }
        } else {

          //no msisdn or no RIO 
          if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/unknown", "8") == '8') {
            continue;
          }
        }
      }
      if (channel.waitForDigit(3000) != '8') {
        loop = false;
      }
    } while (loop);
    /* Useless : catch and exception to throw it (see above) */
    /* } catch (AgiHangupException hangupException) { */
    /*   if (log.isDebugEnabled()) { */
    /*     log.error(hangupException.getMessage(), hangupException); */
    /*   } */
    /*   log.error(hangupException.getMessage()); */
    /*   throw hangupException; */
    /* } */
    callContext.setHangupCause("16");
  }

  @Override
  protected void prepareContext(AgiRequest request, AgiChannel channel,
      CallContext callContext) throws AgiException {
    callContext.setCallingNetwork(VnoConstants.INTERNAL_NETWORK);
    callContext.setCalledNetwork(VnoConstants.EXTERNAL_NETWORK);

    callContext.setCalledNumber(request.getExtension());
    callContext.setCallingAccountCode(getAccountCodeReq(request, channel));

    String callingNumber = channel.getFullVariable("${CALLERID(num)}");
    callContext.setCallingNumber(defaultString(stripStart(callingNumber,
            "+")));
    callContext.setCallingName(defaultString(request.getCallerIdName()));

    callContext.setBothCarrierCodes(getCarrierCodeReq(channel));
    callContext
      .setCalledAccountCode(getCalledAccountCodeFromSipDomainReq(channel));
  }
}
