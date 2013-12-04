package com.initsys.sigal.agent.agi.isdn;

import java.util.concurrent.TimeoutException;

import org.apache.commons.lang.StringUtils;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;

import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.vno.VnoConstants;
import static org.apache.commons.lang.StringUtils.*;

public class IsdnInboundAgi extends AbstracIsdnAgi {

    @Override
    protected void prepareContext(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException {
        callContext.setCallingNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setCalledNetwork(VnoConstants.INTERNAL_NETWORK);
        callContext.setCalledNumber(request.getExtension());

        // ISDN: account code is on the dahdi channel
        String accountCode = request.getAccountCode();
        if (!StringUtils.isBlank(accountCode)) {
            callContext.setCallingAccountCode(accountCode);
        }
        callContext
                .setCallingNumber(defaultString(request.getCallerIdNumber()));
        callContext.setCallingName(defaultString(request.getCallerIdName()));
    }

    @Override
    public void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException, TimeoutException {

        // TODO: transitional block
        {
            handleCall(channel, callContext, "national9", "D200911200001.1");
            return;
        }

        // ExdbQueryResponse exdbResponse = getTemplate()
        // .queryIntercoByAccountCode(callContext.getCallingAccountCode());
        //
        // switch (exdbResponse.getStatus().getCode()) {
        // case OK:
        // handleCall(channel, callContext, exdbResponse
        // .getInboundNumberingPlan(), exdbResponse.getCarrierCode());
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

    private void handleCall(AgiChannel channel, CallContext callContext,
            String inboundNumberingPlan, String carrierCode)
            throws AgiException {

        getCallNormalizer().normalizeInbound(callContext, inboundNumberingPlan,
                null);
        callContext.setCallingCarrierCode(carrierCode);
        callContext.setCalledCarrierCode(callContext.getCallingCarrierCode());

        // TODO
        // if (!checkCounters(exdbResponse)) {
        // doHangupDueToLimit(channel, callContext);
        // } else {
        sendInitialCdr(callContext);
        dialInbound(channel, callContext);
        // }
    }

    protected void dialInbound(AgiChannel channel, CallContext callContext)
            throws AgiException {
        setCallerIdNum(channel, "+" + callContext.getEffectiveCallingNumber());
        setCallerIdName(channel, callContext.getCallingName());
        setAccountCode(channel, callContext.getCallingAccountCode());
        setCarrierCode(channel, callContext.getCallingCarrierCode());
        addPChargingVectorHeader(callContext.getIcid(), channel);
        dial(getGwChannelName()[0], "", callContext.getEffectiveCalledNumber(),
                getInEstablishmentTimeout(), null, channel, ",", false, callContext);
    }
}
