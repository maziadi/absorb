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
import com.initsys.sigal.agent.agi.OutgoingAccountException;
import com.initsys.sigal.agent.agi.LimitReachedException;
import com.initsys.sigal.numbers.NatureOfAddress;
import com.initsys.sigal.numbers.PhoneAddress;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.NpdbQueryResponse;
import com.initsys.sigal.vno.VnoConstants;

public class Ss7InboundAgi extends AbstractFtAgi {

    /** logger */
    static final Logger log = LoggerFactory.getLogger(Ss7InboundAgi.class);

    @Override
    protected void prepareContext(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException {
        callContext.setCallingNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setCalledNetwork(VnoConstants.INTERNAL_NETWORK);
        callContext.setRedirectedFrom(channel
                .getVariable(VnoConstants.REDIRECTED_FROM));
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
        // recuperation accountcode
        String accountCode = request.getAccountCode();
        if (isBlank(accountCode) && !callContext.isRedirected()) {
          throw new OutgoingAccountException("Not a redirection and destination not found: no incoming account for this destination");
        }
        callContext.setCallingAccountCode(accountCode);

        // recupere les champs ISUP
        IsupInRdnis inIsup;
        try {
            inIsup = parseIsup(channel);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Can not parse ISUP: " + e.getMessage());
        }

        // recuperation du numero appele
        PhoneAddress address = null;
        try {
            address = new PhoneAddress(request.getExtension(), NatureOfAddress
                    .decode(inIsup.getCalledNadi()));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Called NADI is invalid: " + e.getMessage());
        }

        // gestion si portabilite entrante
        address.setNumber(checkIncomingPortability(address.getNumber(),
                callContext));

        callContext.setCalledNumber(address.getNumber());
        callContext.setEffectiveCalledNumber(address.e164Number(FRANCE_E164_PREFIX));

        // verification du compte entrant
        ExdbQueryResponse exdbResponse = getTemplate()
                .queryIntercoByAccountCode(callContext.getCallingAccountCode());

        switch (exdbResponse.getStatus().getCode()) {
        case OK:
            callContext.setBothCarrierCodes(exdbResponse.getCarrierCode());
            // initialisation privacy
            callContext.setPrivacy(inIsup.getCallingPres() != 0);

            // gestion de l'identite
            String identityNumber = request.getCallerIdNumber();
            PhoneAddress idNum;
            if (isBlank(identityNumber)) {
                idNum = PhoneAddress.fromE164(exdbResponse.getSubscriberNumber(), FRANCE_E164_PREFIX);
                log.warn("No calling Number given, using subscriber_number as identity number");
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

            // gestion de l'appelant
            boolean validGen = false;
            NatureOfAddress genNadi = null;
            if (!isBlank(inIsup.getGenNumber()) && inIsup.genValid()) {
                try {
                    PhoneAddress genNum = new PhoneAddress(inIsup.getGenNumber(),
                            NatureOfAddress.decode(inIsup.getGenNadi()));
                    callContext.setCallingNumber(genNum.getNumber());
                    callContext.setEffectiveCallingNumber(genNum.e164Number(FRANCE_E164_PREFIX));
                    // application privacy
                    if (inIsup.getGenAddressPresentationIndicator() != 0) {
                        callContext.setPrivacy(true);
                    }
                    validGen = true;
                } catch (IllegalArgumentException e) {
                    log.warn("Generic number is invalid : " + e.getMessage());
                }
            }
            if (!validGen) {
                if (log.isDebugEnabled()) {
                    log.debug("Invalid or innexistant Generic number");
                }
                if(callContext.getEffectiveCallingIdentityNumber().equals(exdbResponse.getSubscriberNumber())) {
                  callContext.setPrivacy(true);
                }

                callContext.setCallingNumber(callContext.getCallingIdentityNumber());
                callContext.setEffectiveCallingNumber(callContext.getEffectiveCallingIdentityNumber());
            }

            if (!checkCounters(exdbResponse, true)) {
              // Unreachable block due to checkCounters implementation
              throw new LimitReachedException("Limit reached : a counter has reached its max value");
               // no getLocked check in inbound context
            } else {
                handleCall(request, channel, inIsup, callContext);
            }
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

    private void handleCall(AgiRequest request, AgiChannel channel,
            IsupInRdnis inIsup, CallContext callContext)
        throws TimeoutException, AgiException {
        NpdbQueryResponse npdbResponse = getTemplate().queryPorted(
                callContext.getEffectiveCalledNumber());

        if (npdbResponse.hasPrefix()) {
            handleCallAsPorted(request, channel, npdbResponse, inIsup,
                    callContext);
            return;
        }

        // Verifie le numero appele pour les cas de redirections
        LidbQueryResponse lidbResponse = getTemplate().queryLineInfoByNumber(
                callContext.getEffectiveCalledNumber());

        switch (lidbResponse.getStatus().getCode()) {
        case OK:
            if (isRedirectionAndIsAllowed(inIsup, lidbResponse)
                    && !callContext.isRedirected()) {
                handleCallAsRedirected(request, channel, lidbResponse, inIsup,
                        callContext);
                return;
            }
            break;
        case NOT_FOUND:
            if (callContext.isRedirected()) {
                redirectToFt(request, channel, inIsup, callContext);
                return;
            }
            break;
        default:
            throw new RuntimeException(
                    "An error occured while querying LIDB for number '"
                            + callContext.getEffectiveCalledNumber() + "'");
        }
        handleInboundCall(request, channel, inIsup, callContext);
    }

    /**
     * @param inIsup
     * @param lidbResponse
     * @return true if redirection is allowed (based on redirection counter).
     */
    private boolean isRedirectionAndIsAllowed(IsupInRdnis inIsup,
            LidbQueryResponse lidbResponse) {
        return lidbResponse.hasRedirectTo()
                && (inIsup.getRedRedirectionCounter() == null || inIsup
                        .getRedRedirectionCounter() < 5);
    }

    /**
     * Checks <code>number</code> is prefixe with one of the
     * <code>portabilityPrefixes</code>.
     * 
     * @param number
     *            Number to check for a portability prefix.
     * @param callContext
     * @return The same number if not ported, the number striped of it's prefix
     *         if ported.
     */
    private String checkIncomingPortability(String number,
            CallContext callContext) {
        if (number.length() == 14) {
            String prefix = number.substring(0, 5);

            if (log.isInfoEnabled()) {
                log.info(number + " was ported (prefix = " + prefix + ")");
            }
            number = number.substring(5);
        }
        return number;
    }

    private void handleCallAsRedirected(AgiRequest request, AgiChannel channel,
            LidbQueryResponse lidbRedirector, IsupInRdnis inIsup, CallContext callContext)
            throws AgiException, TimeoutException {
        callContext.setEffectiveCallingNumber(callContext.getCallingNumber());
        callContext.setEffectiveCallingIdentityNumber(callContext.getCallingIdentityNumber());
        PhoneAddress calledNumber = PhoneAddress.fromE164(callContext.getEffectiveCalledNumber(), FRANCE_E164_PREFIX);

        if (log.isDebugEnabled()) {
            log.debug("Handling redirection from '" + calledNumber.getNumber()
                    + "' to '" + lidbRedirector.getRedirectTo() + "'");
        }
        PhoneAddress redirectNumber = PhoneAddress.fromE164(lidbRedirector
                .getRedirectTo(), FRANCE_E164_PREFIX);

        callContext.setCalledNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setCalledAccountCode(callContext.getCallingAccountCode());
        callContext.setEffectiveCalledNumber(redirectNumber.getNumber());
        callContext.setEndCause(VnoConstants.CAUSE_REDIRECT);
        channel.setVariable(VnoConstants.REDIRECTED_FROM, calledNumber
                .addressNumber());
        exec("Goto", callContext.getEffectiveCalledNumber() + ",1", channel);
        callContext.setEndCause("200/Redirection");
    }

    private void redirectToFt(AgiRequest request, AgiChannel channel,
            IsupInRdnis inIsup, CallContext callContext) throws AgiException {
        callContext.setEffectiveCallingNumber(callContext.getCallingNumber());
        callContext.setEffectiveCallingIdentityNumber(callContext.getCallingIdentityNumber());
        PhoneAddress calledNumber = PhoneAddress.fromE164(callContext.getEffectiveCalledNumber(), FRANCE_E164_PREFIX);
        PhoneAddress initiallyCalledAddress = PhoneAddress.parse(callContext
                .getRedirectedFrom());

        setRedirectionInformation(initiallyCalledAddress, inIsup);

        setCallerIdNum(channel, callContext.getEffectiveCallingNumber());
        
        // Set calling pres
        inIsup.setCallingPres(callContext.getPrivacy() ? (short)1 : (short)0);
        inIsup.setCallingScreen((short)3);

        setIsup(channel, inIsup);

        callContext.setCalledNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setEffectiveCalledNumber(calledNumber.getNumber());
        callContext.setCalledAccountCode(callContext.getCallingAccountCode());
        dialOutbound(getChannelNameFromAddress(calledNumber), "", calledNumber,
                getOutEstablishmentTimeout(), channel, callContext);
    }

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

    private void handleCallAsPorted(AgiRequest request, AgiChannel channel,
            NpdbQueryResponse npdbResponse, IsupInRdnis inIsup,
            CallContext callContext) throws AgiException {
        callContext.setEffectiveCallingNumber(callContext.getCallingNumber());
        callContext.setEffectiveCallingIdentityNumber(callContext.getCallingIdentityNumber());

        if (log.isDebugEnabled()) {
            log.debug("  Porting '" + npdbResponse.getNumber() + "' to '"
                    + npdbResponse.getPrefix() + "'");
        }
        PhoneAddress portedNumber = PhoneAddress.fromE164(npdbResponse
                .getNumber(), FRANCE_E164_PREFIX);
        IsupInRdnis isup = new IsupInRdnis(inIsup.getCallingPartyIndicator());

        isup.setIam(inIsup.getIam());

        // Set calling pres
        PhoneAddress callerAddress = PhoneAddress.fromE164(callContext
        .getCallingNumber(), FRANCE_E164_PREFIX);
        isup.setCallingPres(callContext.getPrivacy() ? (short)1 : (short)0);
        isup.setCallingScreen((short)3);
        isup.setCallingNadi(Short.valueOf(callerAddress.getCallingNadi()));

        setIsup(channel, isup);

        callContext.setCalledNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setEffectiveCalledNumber(npdbResponse.getPrefix()
                + portedNumber.getNumber());
        callContext.setCalledAccountCode(callContext.getCallingAccountCode());
        dialOutbound(getChannelNameFromAddress(portedNumber), npdbResponse
                .getPrefix(), portedNumber, getOutEstablishmentTimeout(),
                channel, callContext);
    }
}
