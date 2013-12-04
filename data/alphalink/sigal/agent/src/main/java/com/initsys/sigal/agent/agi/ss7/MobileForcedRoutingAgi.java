package com.initsys.sigal.agent.agi.ss7;

import static org.apache.commons.lang.StringUtils.defaultString;
import static org.apache.commons.lang.StringUtils.isBlank;

import java.util.concurrent.TimeoutException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;
import org.asteriskjava.live.HangupCause;

import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.agent.agi.IncomingAccountException;
import com.initsys.sigal.agent.agi.LimitReachedException;
import com.initsys.sigal.numbers.NatureOfAddress;
import com.initsys.sigal.numbers.PhoneAddress;
import com.initsys.sigal.protocol.Sigal.MlidbQueryResponse;
import com.initsys.sigal.vno.VnoConstants;

public class MobileForcedRoutingAgi extends AbstractFtAgi {

    /** logger */
    static final Logger log = LoggerFactory.getLogger(MobileForcedRoutingAgi.class);

    @Override
    protected void prepareContext(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException {
        callContext.setCallingNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setCalledNetwork(VnoConstants.INTERNAL_NETWORK);
    }
    
    @Override
    protected String getDetails(AgiRequest request, AgiChannel channel) throws AgiException {
        // TODO : return isup (toString method)
        //return getCustomWoomera(channel);
        try {
            return parseIsup(channel).toString();
        } catch (Exception e) {
            return "ISUP not available.";
        }
    }

    @Override
    public void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException, TimeoutException {

        // recupere les champs ISUP
        IsupInRdnis inIsup;
        try {
            inIsup = parseIsup(channel);
        } catch (IllegalArgumentException e) {
            log.error("Can not parse ISUP: " + e.getMessage());
            callContext.setHangupCause(channel.getVariable("HANGUPCAUSE"));
            // TODO : (alex) je comprend pas l'interet de return plutot que de throw l'exception
            return;
        }

        // recuperation du numero appele
        PhoneAddress address = null;
        try {
            address = new PhoneAddress(request.getExtension(), NatureOfAddress
                    .decode(inIsup.getCalledNadi()));
        } catch (IllegalArgumentException e) {
            log.error("Called NADI is invalid");
            throw(e);
        }
        callContext.setCalledNumber(address.getNumber());
        callContext.setEffectiveCalledNumber(address.e164Number(FRANCE_E164_PREFIX));

        // gestion de l'identite
        String identityNumber = request.getCallerIdNumber();
        PhoneAddress idNum = null;
        if (isBlank(identityNumber)) {
          throw new IncomingAccountException("No Msisdn found");
        } else {
          try {
            idNum = new PhoneAddress(identityNumber, NatureOfAddress
                .decode(inIsup.getCallingNadi()));
          } catch (IllegalArgumentException e) {
            log.error("Calling NADI is invalid");
            throw(e);
          }
        }
        callContext.setCallingIdentityNumber(idNum.getNumber());
        callContext.setEffectiveCallingIdentityNumber(idNum.e164Number(FRANCE_E164_PREFIX));

        // verification du compte entrant
        MlidbQueryResponse mlidbResponse = getTemplate()
          .queryMobileLineInfoByMsisdn(callContext.getEffectiveCallingIdentityNumber());

        // recuperation de l'accountcode du compte appelant
        String accountCode = mlidbResponse.getAccountCode();

        switch (mlidbResponse.getStatus().getCode()) {
        case OK:
            callContext.setBothCarrierCodes(mlidbResponse.getCarrierCode());

            // initialisation privacy
            callContext.setPrivacy(inIsup.getCallingPres() != 0);

            // gestion de l'appelant
            callContext.setCallingNumber(callContext.getCallingIdentityNumber());
            callContext.setEffectiveCallingNumber(callContext.getEffectiveCallingIdentityNumber());
            callContext.setCallingAccountCode(accountCode);

            if (!checkCounters(mlidbResponse)) {
              // Unreachable block due to checkCounters implementation
              throw new LimitReachedException("Limit reached : a counter has reached its max value");
            } else {
                handleInboundCall(request, channel, inIsup, callContext);
            }
            break;
        case NOT_FOUND:
            throw new IncomingAccountException ("Unable to find MLIDB msisdn for '"
                    + callContext.getEffectiveCallingIdentityNumber() + "'");
        default:
            throw new RuntimeException ("An error occured while querying MLIDB for msisdn '"
                    + callContext.getEffectiveCallingIdentityNumber() + "'");
        }
    }

    /**
     * @param request
     * @param channel
     * @param inIsup
     * @param callContext
     * @throws AgiException
     */
    private void handleInboundCall(AgiRequest request, AgiChannel channel,
            IsupInRdnis inIsup, CallContext callContext) throws AgiException {
        if (log.isDebugEnabled()) {
            log.debug(String.format("  Handling inbound call %s -- %s",
                    callContext.getEffectiveCallingNumber(), callContext
                            .getEffectiveCalledNumber()));
        }

        // A verifier
        callContext.setEffectiveCallingIdentityNumber("+" + callContext.getEffectiveCallingIdentityNumber());
        callContext.setEffectiveCallingNumber("+" + callContext.getEffectiveCallingNumber());

        setCallerIdNum(channel, callContext.getEffectiveCallingNumber());
        setPAssertedIdentity(channel, callContext.getEffectiveCallingIdentityNumber());
        if (callContext.getPrivacy()) {
            setPrivacy(channel);
        }

        handleInboundDial(channel, callContext, null, false);
    }

    private boolean checkCounters(MlidbQueryResponse mli) {
      if ((mli.hasMaxVnoCalls() && mli.hasVnoCallCount())
          && (mli.getMaxVnoCalls() <= mli.getVnoCallCount())) {
        throw new LimitReachedException("Vno call count reached its maximum ("
            + mli.getVnoCallCount() + "/" + mli.getMaxVnoCalls() +")");
          }
      return true;
    }
}
