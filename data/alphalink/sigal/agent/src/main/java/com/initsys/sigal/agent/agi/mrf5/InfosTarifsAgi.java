package com.initsys.sigal.agent.agi.mrf5;

import java.util.concurrent.TimeoutException;

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

import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;

import com.initsys.sigal.vno.VnoConstants;

import static org.apache.commons.lang.StringUtils.defaultString;
import static org.apache.commons.lang.StringUtils.stripStart;
import static org.apache.commons.lang.StringUtils.stripEnd;
import static org.apache.commons.lang.StringUtils.isBlank;
import static org.apache.commons.lang.StringUtils.defaultString;

// TODO: gestion correcte du redirect entrant
public class InfosTarifsAgi extends AbstractMrf5Agi {
  /** logger */
  static final Logger log = LoggerFactory.getLogger(SviRioAgi.class);

  private String inboundGwChannelName;

  public String getInboundGwChannelName() {
    return inboundGwChannelName;
  }

  public void setInboundGwChannelName(String inboundGwChannelName) {
    this.inboundGwChannelName = inboundGwChannelName;
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

    boolean loop = true;
    channel.answer();
    sleep(2000);
    sendInitialCdr(callContext);

    do {
      if(channel.streamFile("/var/lib/asterisk/sounds/svi_rio_films/welcome_date", "8") == '8') {
        continue;
      }
      if (channel.waitForDigit(3000) != '8') {
        loop = false;
      }
    } while (loop);
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
