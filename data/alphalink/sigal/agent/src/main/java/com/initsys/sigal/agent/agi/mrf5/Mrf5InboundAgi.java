package com.initsys.sigal.agent.agi.mrf5;

import static org.apache.commons.lang.StringUtils.defaultString;
import static org.apache.commons.lang.StringUtils.stripStart;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_BUSY;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_INTERWORKING;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_INVALID_NUMBER_FORMAT;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_NETWORK_OUT_OF_ORDER;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_NORMAL_CIRCUIT_CONGESTION;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_NORMAL_CLEARING;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_NORMAL_UNSPECIFIED;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_RECOVERY_ON_TIMER_EXPIRE;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_SWITCH_CONGESTION;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_UNALLOCATED;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_NO_ANSWER;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_CALL_REJECTED;
import static org.asteriskjava.live.HangupCause.AST_CAUSE_INVALID_CALL_REFERENCE;

import java.util.List;
import java.util.concurrent.TimeoutException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;
import org.asteriskjava.live.HangupCause;

import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.agent.agi.IncomingAccountException;
import com.initsys.sigal.agent.agi.LimitReachedException;
import com.initsys.sigal.numbers.PhoneAddress;
import com.initsys.sigal.numbers.PhoneNumberUtils;
import com.initsys.sigal.protocol.Sigal.EmdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;
import com.initsys.sigal.vno.VnoConstants;
import com.initsys.sigal.vno.VnoUtils;

public class Mrf5InboundAgi extends AbstractMrf5Agi {

    private String[] emergencyNumbers;
    private Boolean handleLocalCalls = true;

    public Boolean getHandleLocalCalls() {
        return handleLocalCalls;
    }

    public void setHandleLocalCalls(Boolean handleLocalCalls) {
        this.handleLocalCalls = handleLocalCalls;
    }

    public String[] getEmergencyNumbers() {
        return emergencyNumbers;
    }

    public void setEmergencyNumbers(String[] emergencyNumbers) {
        this.emergencyNumbers = emergencyNumbers;
    }

    /** logger */
    private static final Logger log = LoggerFactory.getLogger(Mrf5InboundAgi.class);

    @Override
    protected void prepareContext(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException {
        callContext.setCallingNetwork(VnoConstants.EXTERNAL_NETWORK);
        callContext.setCalledNetwork(VnoConstants.INTERNAL_NETWORK);
        callContext.setCallingAccountCode(getAccountCodeReq(request, channel));

        callContext.setCallingNumber(defaultString(stripStart(request
                        .getCallerIdNumber(), "+")));
        callContext.setCallingName(defaultString(request.getCallerIdName()));
        callContext.setCalledNumber(defaultString(stripStart(request
                        .getExtension(), "+")));
        callContext.setPrivacy("id".equals(channel.getVariable("SIP_HEADER(Privacy)")));
    }

    @Override
    public void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException, TimeoutException {
        boolean privacy = false;
        LidbQueryResponse liDialer = null;

        liDialer = getTemplate().queryLineInfoByAccountCode(
                callContext.getCallingAccountCode());
        switch (liDialer.getStatus().getCode()) {
          case OK:
            // Empty
            break;
          case NOT_FOUND: 
            throw new IncomingAccountException("Unable to find LIDB account for '"
                + callContext.getCallingAccountCode() + "'");
          default: 
            throw new RuntimeException(
                    "An error occured while querying LIDB for account '"
                + callContext.getCallingAccountCode() + "'");
        }

        boolean announce = liDialer.hasIndication()
            && !liDialer.getIndication();
        callContext.setBothCarrierCodes(liDialer.getCarrierCode());

        boolean nationalToe164 = "national".equals(liDialer
                .getInboundNumberingPlan());
        if (nationalToe164) {
            if (callContext.getCalledNumber().startsWith("3651")) {
                callContext.setCalledNumber(callContext.getCalledNumber()
                        .substring(4));
                privacy = true;
            }
            // TODO : verification de la validite du numero

            callContext.setEffectiveCalledNumber(PhoneNumberUtils
                    .nationalToE164(callContext.getCalledNumber(),
                        FRANCE_E164_PREFIX));

        } else {
            callContext.setEffectiveCalledNumber(callContext.getCalledNumber());
        }

        handleCallingNumberAndName(channel, privacy, liDialer, nationalToe164, callContext);

        LidbQueryResponse numberInfo = getTemplate().queryLineInfoByNumber(
                StringUtils.stripStart(callContext.getEffectiveCallingNumber(), "+"));

        boolean isFax = checkAndHandleFaxNumber(callContext, numberInfo);

        handleCallingIdentityNumber(channel, liDialer, numberInfo, nationalToe164, callContext);

        if (checkForEmergencyNumber(callContext.getCalledNumber())) {
            callContext.setCalledCarrierCode(VnoConstants.EMERGENCY_CARRIER);
            setAccountCode(channel, callContext.getCallingAccountCode());
            setCarrierCode(channel, callContext.getCalledCarrierCode());
            handleEmergencyTranslation(liDialer, numberInfo, request, channel,
                    callContext.getEffectiveCallingNumber(), callContext);
            return;
        }

        if (announce) {
          try {
            checkCounters(liDialer, true);
          } catch (LimitReachedException e) {
            String msg = "Limit reached on call " + callContext.getIcid()  + " : " + e.getMessage();
            if (log.isDebugEnabled()) {
              log.info(msg, e);
            } else {
              log.info(msg);
            }
            setCarrierCode(channel, callContext.getCalledCarrierCode());
            handleAnnounce(AST_CAUSE_NORMAL_UNSPECIFIED, channel, callContext);
            return;
          }
        } else if (!checkCounters(liDialer, true)) {
            // Unreachable block due to checkCounters implementation
            throw new LimitReachedException("Limit reached : a counter has reached its max value");
        }

        if (liDialer.getLocked()) {
            if(announce) {
              String msg = "Limit reached on call " + callContext.getIcid()  + " : Account is locked";
              log.info(msg);
              setCarrierCode(channel, callContext.getCalledCarrierCode());
              handleAnnounce(AST_CAUSE_NORMAL_UNSPECIFIED, channel, callContext);
            } else {
                throw new LimitReachedException("Account is locked");
            }
            return;
        }
        /* Voicemail not yet implemented */
        /* if ("33888".equals(callContext.getEffectiveCalledNumber())) { */
        /*     // TODO : et si numberInfo a pour status NOT_FOUND ??? */
        /*     if(!liDialer.getSubscriberNumber().equals(numberInfo.getSubscriberNumber())) { */
        /*         // TODO : end cause a normaliser */
        /*         doHangup(channel, AST_CAUSE_INVALID_CALL_REFERENCE, callContext); */
        /*     } else { */
        /*         doDialVoicemail(channel, callContext, liDialer); */
        /*     } */
        /*     return; */
        /* } */

        if (isShortNumber(callContext.getEffectiveCalledNumber())) {
            callContext
                .setEffectiveCalledNumber(PhoneAddress.SHORT_NUMBERS_PREFIX
                        + callContext.getEffectiveCalledNumber().substring(
                            FRANCE_E164_PREFIX.length()));
        }

        handleInboundDial(channel, callContext, announce ? "g" : null,
                isFax);
        if (announce) {
            handleAnnounce(getHangupCause(callContext), channel, callContext);
        }
    }

    private void doDialVoicemail(AgiChannel channel, CallContext callContext,
            LidbQueryResponse liAccount) throws TimeoutException, AgiException {

        callContext.setEffectiveCalledNumber("017888");
        handleInboundDial(channel, callContext, null, false);
    }

    /**
     * Queries LIDB with the calling number to decide if the call should be
     * treated as a fax call.
     * 
     * @param callContext
     * @return
     * @throws TimeoutException
     */
    private boolean checkAndHandleFaxNumber(CallContext callContext,
            LidbQueryResponse numberInfo) throws TimeoutException {
        switch (numberInfo.getStatus().getCode()) {
            case OK:
                if (numberInfo.hasFax() && numberInfo.getFax()) {
                    if (log.isDebugEnabled()) {
                        log.debug(String.format("  %s is marked as a fax number",
                                    callContext.getEffectiveCallingNumber()));
                    }
                    String vnoName = VnoUtils.getVnoName(callContext
                            .getCalledCarrierCode());

                    callContext.setCalledCarrierCode(VnoUtils.composeCarrierCode(
                                vnoName, VnoConstants.FAX_NUMBERING_PLAN_NUMBER));
                    return true;
                }
                break;
            case NOT_FOUND:
                if (log.isDebugEnabled()) {
                    log
                        .debug(String
                                .format(
                                    "Unable to find LIDB entry for callingNumber '%s': assuming it's not a fax number.",
                                    callContext.getEffectiveCallingNumber()));
                }
                break;
            default:
                if (log.isDebugEnabled()) {
                    log
                        .debug(String
                                .format(
                                    "Error while querying LIDB entry for callingNumber '%s': assuming it's not a fax number.",
                                    callContext.getEffectiveCallingNumber()));

                }
                break;
        }
        return false;
    }

    private void handleAnnounce(HangupCause cause, AgiChannel channel, CallContext callContext)
        throws AgiException {
        // On compare les code car certaines causes remontent sous deux noms
    // différents mais
// avec le même code.

        if (AST_CAUSE_NORMAL_CLEARING.getCode() == cause.getCode()) {
          //channel.hangup();
        } else if (AST_CAUSE_BUSY.getCode() == cause.getCode()) {
          dialAnnounce("0486", channel, cause, callContext);
        } else if (AST_CAUSE_UNALLOCATED.getCode() == cause.getCode()) {
          dialAnnounce("0404", channel, cause, callContext);
        } else if (AST_CAUSE_NORMAL_CIRCUIT_CONGESTION.getCode() == cause.getCode()
            || AST_CAUSE_SWITCH_CONGESTION.getCode() == cause.getCode()
            || AST_CAUSE_NORMAL_UNSPECIFIED.getCode() == cause.getCode()
            || AST_CAUSE_NETWORK_OUT_OF_ORDER.getCode() == cause.getCode()
            || AST_CAUSE_RECOVERY_ON_TIMER_EXPIRE.getCode() == cause.getCode()
            || AST_CAUSE_INTERWORKING.getCode() == cause.getCode()
            || AST_CAUSE_NO_ANSWER.getCode() == cause.getCode()) {
          dialAnnounce("0480", channel, cause, callContext);
        } else if (AST_CAUSE_INVALID_NUMBER_FORMAT.getCode() == cause.getCode()
            || AST_CAUSE_CALL_REJECTED.getCode() == cause.getCode()) {
          dialAnnounce("0484", channel, cause, callContext);
        } else if (AST_CAUSE_INVALID_CALL_REFERENCE.getCode() == cause.getCode()) {
          dialAnnounce("0402", channel, cause, callContext);
        } else {
          log.warn(String.format("Unable to map HANGUP_CAUSE %s", cause));
          //channel.hangup();
        }
    }

    private void dialAnnounce(String number, AgiChannel channel, HangupCause cause, CallContext callContext)
        throws AgiException {
        // TODO Auto-generated method stub
        handleInboundLoadBalancedDial(channel, "016", number,
                getInEstablishmentTimeout(), null, false, getGwChannelName(), callContext);

        callContext.setBillableDuration(0);
        callContext.setHangupCause(Integer.toString(cause.getCode()));
        normalizeAndSetEndCause(callContext);
    }

    void handleCallingNumberAndName(AgiChannel channel, boolean privacy,
            LidbQueryResponse li, boolean nationalToe164,
            CallContext callContext) throws AgiException {
        String callingNumber = callContext.getCallingNumber();
        Pattern nationalPattern = Pattern.compile("^[0-9]{1,17}$");
        Pattern e164Pattern = Pattern.compile("^[0-9]{1,15}$");

        if (log.isDebugEnabled()) {
            log.debug("  CallerId: " + callContext.getCallingName() + " / "
                    + callingNumber);
        }

        if ("Anonymous".equals(callContext.getCallingName()) ||
                "anonymous".equals(callingNumber) ||
                callContext.getPrivacy()
        ) {
            privacy = true;
        }

        if (StringUtils.isBlank(callingNumber) || callingNumber.equals("anonymous")) {
            log.warn("  No CID");
            nationalToe164 = false;
            callingNumber = li.getSubscriberNumber();
        }

        Matcher nationalMatcher = nationalPattern.matcher(callingNumber);
        Matcher e164Matcher = e164Pattern.matcher(callingNumber);

        if ((!nationalMatcher.matches() && nationalToe164) ||
                (!e164Matcher.matches() && !nationalToe164) ||
                callingNumber.startsWith("3389") ||
                callingNumber.startsWith("089") ||
                callingNumber.startsWith("003389")
           ) {
            if (log.isDebugEnabled()) {
                log.debug("  Malformed CID, setting calling number to subscriber number: " + li.getSubscriberNumber());
            }
            nationalToe164 = false;
            callingNumber = li.getSubscriberNumber();
            privacy = true;
        } else if ((li.hasFixedCid() && li.getFixedCid()) ||
                callingNumber.equals(li.getAccountCode())
                ) {
            if (log.isDebugEnabled()) {
                log.debug("  Setting calling number to subscriber number: " + li.getSubscriberNumber());
            }
            nationalToe164 = false;
            callingNumber = li.getSubscriberNumber();
        } else if (nationalToe164) {
                callingNumber = PhoneNumberUtils.nationalToE164(callingNumber,
                        FRANCE_E164_PREFIX);
        }
        callContext.setEffectiveCallingNumber("+" + callingNumber);

        if (privacy) {
            if (log.isDebugEnabled()) {
                log.debug("Enabling privacy");
            }
            callContext.setPrivacy(true);
            setPrivacy(channel);
        }

        setCallerIdNum(channel, callContext.getEffectiveCallingNumber());
        setCallerIdName(channel, callContext.getCallingName());
    }

    void handleCallingIdentityNumber(AgiChannel channel, LidbQueryResponse li,
            LidbQueryResponse numberInfo, boolean nationalToe164,
            CallContext callContext) throws AgiException {
        String identityNumber = li.getSubscriberNumber();

        switch (numberInfo.getStatus().getCode()) {
            case OK:
                if (!numberInfo.getAccountCode().equals(li.getAccountCode())) {
                    if (log.isDebugEnabled()) {
                        log.debug(String.format("'%s' is not a number of account '%s' but '%s', "
                                    + "identity will be set to subscriber number",
                                    callContext.getCallingNumber(),
                                    li.getAccountCode(),
                                    numberInfo.getAccountCode()));
                    }
                } else {
                    identityNumber = StringUtils.stripStart(callContext.getEffectiveCallingNumber(), "+");
                }
                break;
            case NOT_FOUND:
                if (log.isDebugEnabled()) {
                    log.debug(String.format("Unable to find LIDB entry for callingNumber '%s': " +
                                "assuming it is not included in account '%s'",
                                callContext.getEffectiveCallingNumber(),
                                callContext.getCallingAccountCode()));
                }
                break;
            default:
                if (log.isDebugEnabled()) {
                    log.debug(String.format("Unable to find LIDB entry for callingNumber '%s': " +
                                "assuming it is not included in account '%s'",
                                callContext.getEffectiveCallingNumber(),
                                callContext.getCallingAccountCode()));
                }
                break;
        }
        callContext.setCallingIdentityNumber(identityNumber);
        callContext.setEffectiveCallingIdentityNumber("+" + identityNumber);

        setPAssertedIdentity(channel, callContext.getEffectiveCallingIdentityNumber());
    }

    private void handleEmergencyTranslation(LidbQueryResponse liDialer,
            LidbQueryResponse numberInfo, AgiRequest request, AgiChannel channel,
            String callerId, CallContext callContext) throws TimeoutException, AgiException {
        String inseeCode;

        if (numberInfo.getStatus().getCode() == ResponseStatusCode.OK) {
            if (numberInfo.getAccountCode().equals(
                        liDialer.getAccountCode())) {
                inseeCode = numberInfo.getInseeCode();
            } else {
                log
                    .error(String
                            .format(
                                "  CID '%s' belongs to account '%s' and not '%s': using account INSEE code",
                                callerId, numberInfo
                                .getAccountCode(), liDialer
                                .getAccountCode()));
                inseeCode = liDialer.getInseeCode();
            }
        } else {
            log.warn(String.format(
                        "  Unregistered CID '%s' using account INSEE code",
                        callerId));
            inseeCode = liDialer.getInseeCode();
        }
        EmdbQueryResponse em = getTemplate().queryEmergency(
                request.getExtension(), inseeCode);

        if (ResponseStatusCode.NOT_FOUND == em.getStatus().getCode()) {
            log.error("  Unable to translate emergency number'"
                    + request.getExtension() + "' / '" + inseeCode + "'");
            return;
        }
        addPChargingVectorHeader(callContext.getIcid(), channel);
        List<String> translations = em.getTranslationList();
        for (String translation : translations) {
            // TODO: traiter le callerID !!!
            handleInboundLoadBalancedDial(channel, "", translation,
                    getInEstablishmentTimeout(), "g", false,
                    getGwChannelName(), callContext);

        }
    }

    private boolean checkForEmergencyNumber(String extension) {
        if (getEmergencyNumbers() == null) {
            log.error("  No emergency number configured!");
        } else {
            for (int i = 0; i < getEmergencyNumbers().length; i++) {
                if (extension.equals(getEmergencyNumbers()[i])) {
                    return true;
                }
            }
        }
        return false;
    }
}
