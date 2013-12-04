package com.initsys.sigal.agent.agi.mrf4;

import static org.apache.commons.lang.StringUtils.defaultString;
import static org.apache.commons.lang.StringUtils.stripStart;

import java.util.concurrent.TimeoutException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.initsys.sigal.agent.agi.IncomingAccountException;
import com.initsys.sigal.agent.agi.LimitReachedException;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;

import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.numbers.PhoneAddress;
import com.initsys.sigal.numbers.PhoneNumberUtils;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.vno.VnoConstants;

public class Mrf4InboundAgi extends AbstractMrf4Agi {
    /** logger */
    static final Logger log = LoggerFactory.getLogger(Mrf4InboundAgi.class);

    @Override
    protected void prepareContext(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException {
        callContext.setCallingNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setCalledNetwork(VnoConstants.INTERNAL_NETWORK);
        callContext.setCalledNumber(defaultString(stripStart(request
                .getExtension(), "+")));

        callContext.setCallingAccountCode(getAccountCodeReq(request, channel));
        callContext
                .setCallingNumber(defaultString(request.getCallerIdNumber()));
        callContext.setCallingName(defaultString(request.getCallerIdName()));
        callContext.setPrivacy("id".equals(channel.getVariable("SIP_HEADER(Privacy)")));
    }

    @Override
    public void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException, TimeoutException {

        ExdbQueryResponse exdbResponse = getTemplate()
                .queryIntercoByAccountCode(callContext.getCallingAccountCode());

        switch (exdbResponse.getStatus().getCode()) {
        case OK:
            handleCall(channel, callContext, exdbResponse);
            break;
        case NOT_FOUND:
            throw new IncomingAccountException("Unable to find EXDB account for '"
                + callContext.getCallingAccountCode() + "'");
        default:
            throw new RuntimeException(
                    "An error occured while querying EXDB for account '"
                + callContext.getCallingAccountCode() + "'");
        }
    }

    private void handleCall(AgiChannel channel, CallContext callContext,
            ExdbQueryResponse exdbResponse) throws AgiException {

        getCallNormalizer().normalizeInbound(callContext,
                exdbResponse.getInboundNumberingPlan(), null);
        callContext.setBothCarrierCodes(exdbResponse.getCarrierCode());
        if (!"anonymous".equals(callContext.getEffectiveCallingNumber())) {
            callContext.setEffectiveCallingNumber("+" + callContext.getEffectiveCallingNumber());
        }
        setCallerIdNum(channel, callContext.getEffectiveCallingNumber());
        setCallerIdName(channel, callContext.getCallingName());
        handleIdentityAndPrivacy(channel, callContext, exdbResponse);
        if (!checkCounters(exdbResponse, true)) {
          // Unreachable block due to checkCounters implementation
          throw new LimitReachedException("Limit reached : a counter has reached its max value");
        } else if (exdbResponse.getLocked()) {
          throw new LimitReachedException("Account is locked");
        } else {
            if (isShortNumber(callContext.getEffectiveCalledNumber())) {
                callContext
                        .setEffectiveCalledNumber(PhoneAddress.SHORT_NUMBERS_PREFIX
                                + callContext.getEffectiveCalledNumber().substring(
                                        FRANCE_E164_PREFIX.length()));
            }
            handleInboundDial(channel, callContext, null, false);
        }
    }

    private void handleIdentityAndPrivacy(AgiChannel channel, CallContext callContext,
            ExdbQueryResponse exdbResponse) throws AgiException {
        String identityNumber = exdbResponse.getSubscriberNumber();
        String identityValue = channel.getVariable("SIP_HEADER(P-Asserted-Identity)");

        if (callContext.getCallingNumber().startsWith("089") ||
            callContext.getCallingNumber().startsWith("3389") ||
            callContext.getCallingNumber().startsWith("003389")
        ) {
            callContext.setPrivacy(true);
        }

        if (callContext.getPrivacy()) {
            setPrivacy(channel);
        }

        if(!StringUtils.isBlank(identityValue)) {
            Pattern PAssertedIdentityPattern = Pattern.compile(".*(<(sip|tel):\\+?([0-9]+)).*");
            Matcher PAssertedIdentityMatcher = PAssertedIdentityPattern.matcher(identityValue);
            if (PAssertedIdentityMatcher.matches()) {
                identityNumber = PAssertedIdentityMatcher.group(3);
                if (exdbResponse.getInboundNumberingPlan().equals("national")) {
                    identityNumber = PhoneNumberUtils.nationalToE164(identityNumber,
                            FRANCE_E164_PREFIX);
                }
            }
        }
        callContext.setCallingIdentityNumber(identityNumber);
        callContext.setEffectiveCallingIdentityNumber("+" + identityNumber);

        setPAssertedIdentity(channel, callContext.getEffectiveCallingIdentityNumber());
    }
}
