package com.initsys.sigal.agent.agi.mrf4;

import java.util.concurrent.TimeoutException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;

import com.initsys.sigal.vno.VnoConstants;
import com.initsys.sigal.vno.VnoUtils;

import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.agent.agi.IdentityException;
import com.initsys.sigal.agent.agi.LimitReachedException;
import com.initsys.sigal.agent.agi.OutgoingAccountException;
import com.initsys.sigal.agent.agi.SipHeaderIcidExtractor;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;

import static org.apache.commons.lang.StringUtils.defaultString;
import static org.apache.commons.lang.StringUtils.stripStart;
import static org.apache.commons.lang.StringUtils.stripEnd;
import static org.apache.commons.lang.StringUtils.isBlank;
import static org.apache.commons.lang.StringUtils.defaultString;

public class Mrf4OutboundAgi extends AbstractMrf4Agi {

    private static final Logger log = LoggerFactory.getLogger(Mrf4OutboundAgi.class);

    protected void dialOutbound(AgiChannel channel, String vno,
            CallContext callContext) throws AgiException {
        sendInitialCdr(callContext);
        addPChargingVectorHeader(callContext.getIcid(), channel);
        dial("SIP/" + vno, "", callContext.getEffectiveCalledNumber(),
                getOutEstablishmentTimeout(), null, channel, ",", false,
                callContext);
    }

    @Override
    protected String getIcid(AgiChannel channel) {
        try {
            return new SipHeaderIcidExtractor().getIcid(channel);
        } catch (IllegalStateException e) {
            // TODO: transitional block: no ICID was found we create a
            // transational one.
            String icid = "t-" + createIcid();
            log.warn("P-Charging-Vector (or ICID variable) was not found."
                        + " Generating a transitional one: "
                        + icid);
            return icid;
        }
    }

    private String getVnoName(CallContext cdr) {
        return VnoUtils.getVnoName(cdr.getCallingCarrierCode());
    }

    private void handleCall(AgiChannel channel, CallContext callContext,
            ExdbQueryResponse exdbResponse) throws AgiException {
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
                exdbResponse.getOutboundNumberingPlan());

        setCallerIdNum(channel, callContext.getEffectiveCallingNumber());
        setCallerIdName(channel, callContext.getCallingName());
        if(privacy) {
          callContext.setPrivacy(true);
          setPrivacy(channel);
        }

        if(!exdbResponse.getWeirdIdentity() || (privacy 
            || (callContext.getEffectiveCallingIdentityNumber() 
              == callContext.getEffectiveCallingNumber()))) {
          setPAssertedIdentity(channel,
              callContext.getEffectiveCallingIdentityNumber());
        }
        setAccountCode(channel, callContext.getCalledAccountCode());
        setCarrierCode(channel, callContext.getCalledCarrierCode());

        if (!checkCounters(exdbResponse, false)) {
          // Unreachable block due to checkCounters implementation
          throw new LimitReachedException("Limit reached : a counter has reached its max value");
        } else {
            dialOutbound(channel, getVnoName(callContext), callContext);
        }
    }

    @Override
    public void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException, TimeoutException {

        ExdbQueryResponse exdbResponse = getTemplate()
                .queryIntercoByAccountCode(callContext.getCalledAccountCode());

        switch (exdbResponse.getStatus().getCode()) {
        case OK:
            handleCall(channel, callContext, exdbResponse);
            break;
        case NOT_FOUND:
            throw new OutgoingAccountException("Unable to find account for '"
                    + callContext.getCalledAccountCode() + "'");
        default:
            throw new RuntimeException(
                    "An error occured while querying for account '"
                            + callContext.getCalledAccountCode() + "'");
        }

    }

    @Override
    protected void prepareContext(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException {
        callContext.setCallingNetwork(VnoConstants.INTERNAL_NETWORK);
        callContext.setCalledNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setCalledNumber(request.getExtension());

        callContext.setBothCarrierCodes(getCarrierCodeReq(channel));

        callContext.setCallingAccountCode(getAccountCodeReq(request, channel));
        callContext.setCallingNumber(
            defaultString(request.getCallerIdNumber()));
        callContext.setCallingName(defaultString(request.getCallerIdName()));

        callContext.setCalledAccountCode(
            getCalledAccountCodeFromSipDomainReq(channel));
    }
}
