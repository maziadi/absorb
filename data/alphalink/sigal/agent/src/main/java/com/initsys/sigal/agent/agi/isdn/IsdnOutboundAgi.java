package com.initsys.sigal.agent.agi.isdn;

import java.util.concurrent.TimeoutException;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;

import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.agent.agi.SipHeaderIcidExtractor;
import com.initsys.sigal.vno.VnoConstants;

public class IsdnOutboundAgi extends AbstracIsdnAgi {

    // TODO: transitional
    private static final String DEFAULT_SFR_INTERCO_ACCOUNT_CODE = "0991000001014";

    /** logger */
    static final Logger log = LoggerFactory.getLogger(IsdnOutboundAgi.class);

    protected void dialOutbound(AgiChannel channel, CallContext callContext)
            throws AgiException {
        dial(getGwChannelName()[0], "", callContext.getEffectiveCalledNumber(),
                getOutEstablishmentTimeout(), null, channel, ",", false, callContext);

    }

    @Override
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

    private void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext, String outboundNumberingPlan)
            throws AgiException {
        getCallNormalizer().normalizeOutbound(callContext,
                outboundNumberingPlan);

        setCallerPres(
                channel,
                isPresentationProhibited(request, channel) ? "prohib_not_screened"
                        : "allowed");
        setCallerIdNum(channel, callContext.getEffectiveCallingNumber());
        setCallerIdName(channel, callContext.getCallingName());
        callContext.setCalledAccountCode(DEFAULT_SFR_INTERCO_ACCOUNT_CODE);
        // TODO transitional
        // if (!checkCounters(exdbResponse)) {
        // doHangupDueToLimit(channel, callContext);
        // } else {
        sendInitialCdr(callContext);
        dialOutbound(channel, callContext);
        // }
    }

    @Override
    public void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException, TimeoutException {

        // TODO: transitional
        {
            handleCall(request, channel, callContext, "mix_nat_intl");
            return;
        }

        // ExdbQueryResponse exdbResponse = getTemplate()
        // .queryIntercoByAccountCode(callContext.getCalledAccountCode());
        // 
        // switch (exdbResponse.getStatus().getCode()) {
        // case OK:
        // handleCall(channel, callContext, exdbResponse
        // .getOutboundNumberingPlan());
        // break;
        // case NOT_FOUND:
        // throw new CallException("Unable to find account for '"
        // + callContext.getCalledAccountCode() + "'");
        // default:
        // throw new CallException(
        // "An error occured while querying for account '"
        // + callContext.getCalledAccountCode() + "'");
        // }

    }

    @Override
    protected void prepareContext(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException {
        callContext.setCallingNetwork(VnoConstants.INTERNAL_NETWORK);
        callContext.setCalledNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setCalledNumber(request.getExtension());

        // TODO: transitional use the XXXReq methods in final version.
        String carrierCode = getCarrierCode(channel);
        if (!StringUtils.isBlank(carrierCode)) {
            callContext.setCalledCarrierCode(carrierCode);
            callContext.setCallingCarrierCode(carrierCode);
        }
        String accountCode = getAccountCode(request, channel);
        if (!StringUtils.isBlank(accountCode)) {
            callContext.setCallingAccountCode(accountCode);
        }

        callContext.setCallingName(StringUtils.defaultString(request.getCallerIdName()));
        callContext.setCallingNumber(request.getCallerIdNumber());

        // TODO : transitional
        accountCode = getCalledAccountCodeFromSipDomain(channel);
        if (accountCode != null) {
            callContext.setCalledAccountCode(accountCode);
        }
    }
}
