package com.initsys.sigal.agent.agi.mrf5;

import java.util.concurrent.TimeoutException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;

import com.initsys.sigal.numbers.PhoneNumberUtils;

import com.initsys.sigal.agent.agi.IdentityException;
import com.initsys.sigal.agent.agi.OutgoingAccountException;
import com.initsys.sigal.agent.agi.LimitReachedException;
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
public class Mrf5OutboundAgi extends AbstractMrf5Agi {
    /** logger */
    static final Logger log = LoggerFactory.getLogger(Mrf5OutboundAgi.class);

    private String[] inboundGwChannelName;

    public String[] getInboundGwChannelName() {
        return inboundGwChannelName;
    }

    public void setInboundGwChannelName(String[] inboundGwChannelName) {
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

    @Override
    public void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException, TimeoutException {
        LidbQueryResponse lidbResponse = getTemplate().queryLineInfoByNumber(
                callContext.getCalledNumber());

        switch (lidbResponse.getStatus().getCode()) {
          case OK:
            // Empty
            break;
          case NOT_FOUND:
            throw new OutgoingAccountException("Called account not found");
          default:
            throw new RuntimeException(
                "An error occured while querying LIDB for number '"
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

        // normaliser selon plan de numerotation (name aussi)
        getCallNormalizer().normalizeOutbound(callContext,
                lidbResponse.getOutboundNumberingPlan());

        if(privacy) {
          callContext.setPrivacy(true);
          callContext.setEffectiveCallingNumber("anonymous");
          callContext.setCallingName("Anonymous");
          setPrivacy(channel);
        }

        setCallerIdNum(channel, callContext.getEffectiveCallingNumber());
        setCallerIdName(channel, callContext.getCallingName());
        setAccountCode(channel, callContext.getCalledAccountCode());

        int answerTimeout = getAnswerTimeout(lidbResponse);

        if (!checkCounters(lidbResponse, false)) {
          // Unreachable block due to checkCounters implementation
          /* Voicemail not yet implemented */
          /* if (hasVoicemail(lidbResponse)) { */
          /*   dialVoicemail(channel, callContext); */
          /* } else { */
            throw new LimitReachedException("Limit Reached");
          /* } */
          /* return; */
        }
        /* Voicemail not yet implemented */
        /* if (hasVoicemail(lidbResponse) && lidbResponse.getVoicemail() == 0) { */
        /*   dialVoicemail(channel, callContext); */
        /*   return; */
        /* } */
        sendInitialCdr(callContext);
        dialOutbound(lidbResponse, channel,
            callContext.getEffectiveCalledNumber(),
            answerTimeout, callContext);
        /* Voicemail not yet implemented */
        /* if (hasVoicemail(lidbResponse)) { */
        /*     String status = callContext.getDialStatus(); */

        /*     if (!"ANSWER".equals(status) && !"CANCEL".equals(status)) { */
        /*         dialVoicemail(channel, callContext); */
        /*     } */
        /* } */
    }

    private boolean hasVoicemail(LidbQueryResponse lidbResponse) {
      return lidbResponse.hasVoicemail() && lidbResponse.getVoicemail() >= 0;
    }

    /**
     * Dial voicemail (prefix 017 to the called number).
     * 
     * @param channel
     * @param callContext
     * @throws AgiException
     */
    private void dialVoicemail(AgiChannel channel, CallContext callContext)
      throws AgiException {
      callContext.setEndCause("VOICEMAIL");
      setCarrierCode(channel, callContext.getCalledCarrierCode());
      addPChargingVectorHeader(callContext.getIcid(), channel);
      handleInboundLoadBalancedDial(channel, "017",
              PhoneNumberUtils.e164toNational(callContext.getCalledNumber(),
                  FRANCE_E164_PREFIX),
              10, null, false, getInboundGwChannelName(), callContext);
    }

    /**
     * If no voicemail answer timeout is set or if it's n<= 0 use
     * {@link #getOutEstablishmentTimeout()}, if voice mail timeout is positive
     * use it as call answer timeout.
     * 
     * @param liDialer
     * @return Calculated answer timeout.
     */
    private int getAnswerTimeout(LidbQueryResponse liDialer) {
      /* Voicemail not yet implemented */
      /* if (liDialer.hasVoicemail() && liDialer.getVoicemail() > 0) { */
      /*   return liDialer.getVoicemail(); */
      /* } */
      return getOutEstablishmentTimeout();
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
