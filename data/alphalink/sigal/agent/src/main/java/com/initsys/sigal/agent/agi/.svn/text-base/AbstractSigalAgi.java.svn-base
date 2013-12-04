package com.initsys.sigal.agent.agi;

import java.util.Date;
import java.util.UUID;
import java.util.concurrent.TimeoutException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.Random;
import java.util.List;
import org.apache.commons.lang.ArrayUtils;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.time.StopWatch;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.util.NumberUtils;

import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;
import org.asteriskjava.fastagi.AgiScript;
import org.asteriskjava.live.HangupCause;

import com.initsys.sigal.agent.AgentStatistics;
import com.initsys.sigal.agent.DummyAgentStatistics;
import com.initsys.sigal.agent.SigalAgentTemplate;

import com.initsys.sigal.agent.agi.SipHeaderIcidExtractor;

import com.initsys.sigal.protocol.Sigal.Cdr;

public abstract class AbstractSigalAgi implements AgiScript {

    /** logger */
    private static final Logger log = LoggerFactory.getLogger(AbstractSigalAgi.class);

    protected static final String FRANCE_E164_PREFIX = "33";

    private static final Pattern SIP_DOMAIN_PATTERN = Pattern
            .compile("([0-9]{13})\\.[a-z0-9-]+\\.sip\\.openvno\\.net(:[0-9]*)?");

    private static final Pattern shortNumberPattern = Pattern.compile(FRANCE_E164_PREFIX
            + "(3...|118...|10..)");

    private AgentStatistics statistics = new DummyAgentStatistics();

    public AgentStatistics getStatistics() {
        return statistics;
    }

    public void setStatistics(AgentStatistics statistics) {
        this.statistics = statistics;
    }

    private SigalAgentTemplate template;

    /** Prefix for calls going towards our network. */
    private String[] gwChannelName;

    /** Time to wait before the call is established. */
    private int outEstablishmentTimeout;

    /** Time to wait before the call is established. */
    private int inEstablishmentTimeout;

    /** Sigal node name (logical name of the node) */
    private String nodeName;

    /** Random object used for load-balancing */
    private Random random;

    public String getNodeName() {
        return nodeName;
    }

    public void setNodeName(String nodeName) {
        this.nodeName = nodeName;
    }

    public Random getRandom() {
        return random;
    }

    public void setRandom(Random random) {
        this.random = random;
    }

    public SigalAgentTemplate getTemplate() {
        return template;
    }

    public void setTemplate(SigalAgentTemplate template) {
        this.template = template;
    }

    private String getCallData(AgiRequest request, AgiChannel channel) {
        String details = null;
        try {
            details = getDetails(request, channel);
        } catch (AgiException e) {
            details = "Exception while getting details: " + e.getMessage();
        }
        return request.getCallerIdName() + " <" + request.getCallerIdNumber()
                + ">, ext=" + request.getExtension() + ", channel="
                + request.getChannel() + ", " + request.getDnid() + ", "
                + details;
    }

    protected String getDetails(AgiRequest request, AgiChannel channel)
            throws AgiException {
        return "no details.";
    }

    protected String createIcid() {
        return UUID.randomUUID().toString();
    }

    protected void addPChargingVectorHeader(String icid, AgiChannel channel)
            throws AgiException {
        exec(
                "SipAddHeader",
                "P-Charging-Vector: "
                        + ("icid-value=" + icid + "; icid-generated-at=" + getNodeName()),
                channel);
    }

    /**
     * Method called when a service request is handled.
     * 
     * @param request
     * @param channel
     * @param callContext
     *            CDR object to fill out by the implementing method.
     * @throws AgiException
     * @throws TimeoutException
     */
    public abstract void handleCall(AgiRequest request, AgiChannel channel,
            CallContext callContext) throws AgiException, TimeoutException;

    public String[] getGwChannelName() {
        return gwChannelName;
    }

    public void setGwChannelName(String[] gwChannelName) {
        this.gwChannelName = gwChannelName;
    }

    private void logRequest(Logger log, AgiRequest request, AgiChannel channel,
            boolean begin, boolean error, Long duration) {
        if (log.isDebugEnabled()) {
            log.debug((begin ? "BEGIN: " : "END  : ")
                    + (duration == null ? "" : duration + ": ")
                    + (error ? "ERROR: " : "") + getCallData(request, channel));
        }
    }

    /**
     * Called by the AGI server. Handles the request.
     */
    public void service(AgiRequest request, AgiChannel channel)
            throws AgiException {
        boolean error = false;
        boolean doFinally = true;
        Logger log = LoggerFactory.getLogger(this.getClass());
        StopWatch watch = new StopWatch();

        logRequest(log, request, channel, true, false, null);
        watch.start();
        getStatistics().incrementCallCount();

        CallContext callContext = initializeCdr();

        try {
            handleIcid(callContext, channel);
            callContext.computeDuration();
            prepareContext(request, channel, callContext);
            handleCall(request, channel, callContext);
            if(!callContext.hasEndCause()) {
              doHangupAndSetEndCause(channel, callContext);
            }
        } catch (TimeoutException e) {
          error = true;
          String msg = "  Timeout occured while handling call "
            + getCallData(request, channel);
          getStatistics().incrementExceptionCount();
          log.error(msg, e);
          protectedNoOp(channel, msg);
          callContext.setEndCause("500/Timeout");
          callContext.setMessage(msg);
          doHangup(channel, HangupCause.AST_CAUSE_FAILURE);
        } catch (IdentityException e) {
          error = true; 
          String msg = "No identity number was found for call "
            + getCallData(request, channel);
          getStatistics().incrementExceptionCount();
          if (log.isDebugEnabled()) {
            log.error(msg, e);
          } else {
            log.error(msg);
          }
          callContext.setEndCause("403/MissingIdentity");
          callContext.setMessage(msg);
          doHangup(channel, HangupCause.AST_CAUSE_CALL_REJECTED);
        } catch (OutgoingAccountException e) {
          error = true; 
          String msg = "Called account was not found for call "
            + getCallData(request, channel);
          getStatistics().incrementExceptionCount();
          if (log.isDebugEnabled()) {
            log.error(msg, e);
          } else {
            log.error(msg);
          }
          callContext.setEndCause("404/AccountNotFound");
          callContext.setMessage(msg);
          doHangup(channel, HangupCause.AST_CAUSE_UNALLOCATED);
        } catch (IncomingAccountException e) {
          error = true; 
          String msg = "Calling account was not found for call "
            + getCallData(request, channel);
          getStatistics().incrementExceptionCount();
          if (log.isDebugEnabled()) {
            log.error(msg, e);
          } else {
            log.error(msg);
          }
          callContext.setEndCause("403/AccountNotFound");
          callContext.setMessage(msg);
          doHangup(channel, HangupCause.AST_CAUSE_CALL_REJECTED);
        } catch (LimitReachedException e) {
          error = true; 
          String msg = "Limit reached on call " + callContext.getIcid()  + " : " + e.getMessage();
          if (log.isDebugEnabled()) {
            log.info(msg, e);
          } else {
            log.info(msg);
          }
          callContext.setEndCause("480/LimitReached");
          callContext.setMessage(msg);
          doHangup(channel, HangupCause.AST_CAUSE_NORMAL_UNSPECIFIED);
        } catch (NoGatewayAvailableException e) {
          error = true; 
          String msg = "No more gateway found during failover for call "
            + getCallData(request, channel);
          getStatistics().incrementExceptionCount();
          if (log.isDebugEnabled()) {
            log.error(msg, e);
          } else {
            log.error(msg);
          }
          callContext.setEndCause("480/NoGatewayAvailable");
          callContext.setMessage(msg);
          doHangup(channel, HangupCause.AST_CAUSE_NO_ANSWER);
        } catch (Exception e) {
          error = true;
          String msg = "  Error while handling call "
            + getCallData(request, channel);
          getStatistics().incrementExceptionCount();
          if (log.isDebugEnabled()) {
            log.error(msg, e);
          } else {
            log.error(msg);
          }
          callContext.setEndCause("500/Error");
          callContext.setMessage(msg);
          doHangup(channel, HangupCause.AST_CAUSE_FAILURE);
        } catch (AssertionError e) {
          doFinally = false; // TODO: this code is here only to help unit test
          // failure analysis (remove it!)
          throw e;
        } finally {
          try {
            callContext.stopTreatmentWatch();
          } catch (IllegalStateException e) {
            // nothing
          }
          if (doFinally) {
            watch.stop();
            Cdr cdr = completeCdrAndStats(channel, log, callContext, watch);
            try {
              getTemplate().sendCdrMessage(cdr);
            } catch (RuntimeException e) {
              error = true;
              log.error("  Error while sending CDR message for call " + getCallData(request, channel), e);
              getStatistics().incrementExceptionCount();
            }
            logRequest(log, request, channel, false, error, watch.getTime());
          }
        }
}

    private Cdr completeCdrAndStats(AgiChannel channel, Logger log,
            CallContext callContext, StopWatch watch) {
        try {
          if(!callContext.hasBillableDuration()) {
            callContext.setBillableDuration(getAnsweredTime(channel));
          }
        } catch (AgiException e) {
            log.error("Error while completing CDR", e);
            // ignore
        }

        callContext.complete();
        Cdr cdr = callContext.build();
        getStatistics().addDuration(cdr.getDuration());
        getStatistics().addBillableDuration(cdr.getBillableDuration());
        getStatistics()
                .addTreatmentDuration(callContext.getTreatmentDuration());

        return cdr;
    }

    /**
     * 
     * @param channel
     * @return Le nombre de secondes indiques dans ANSWEREDTIME si prsent. 0
     *         Sinon.
     * @throws IllegalArgumentException
     *             Si ANSWEREDTIME est prsent mais non numrique.
     */
    protected int getAnsweredTime(AgiChannel channel) throws AgiException {
        String answeredTime = channel.getVariable("ANSWEREDTIME");

        if (StringUtils.isBlank(answeredTime)) {
            return 0;
        } else if (StringUtils.isNumeric(answeredTime)) {
            return Integer.parseInt(answeredTime);
        } else {
            throw new IllegalArgumentException("Wrong answered time format : '"
                    + answeredTime + "'");
        }
    }

    protected boolean sendInitialCdr(CallContext callContext) {
        boolean isInitialCdrSent;

        if (log.isDebugEnabled()) {
            log.debug("  Sending initial CDR");
        }
        try {
            callContext.stopTreatmentWatch();
        } catch (IllegalStateException e) {
            // nothing
        }
        getTemplate().sendCdrMessage(callContext.clone().build());
        isInitialCdrSent = true;

        return isInitialCdrSent;
    }

    protected abstract void prepareContext(AgiRequest request,
            AgiChannel channel, CallContext callContext) throws AgiException;

    private void handleIcid(CallContext cdr, AgiChannel channel) {
        String icid = getIcid(channel);
        if (icid == null) {
            icid = createIcid();
        }
        cdr.setIcid(icid);
        // TODO: tests should not need this
        if (getRandom() == null) setRandom(new Random(icid.hashCode()));
    }

    private void protectedNoOp(AgiChannel channel, String msg) {
        try {
            exec("NoOp", msg, channel);
        } catch (Throwable t) {
            // ignore
        }
    }

    public int getInEstablishmentTimeout() {
        return inEstablishmentTimeout;
    }

    public void setInEstablishmentTimeout(int inEstablishmentTimeout) {
        this.inEstablishmentTimeout = inEstablishmentTimeout;
    }

    public int getOutEstablishmentTimeout() {
        return outEstablishmentTimeout;
    }

    public void setOutEstablishmentTimeout(int establishmentTimeout) {
        this.outEstablishmentTimeout = establishmentTimeout;
    }

    protected int exec(String application, String data, AgiChannel channel)
            throws AgiException {
        Logger log = LoggerFactory.getLogger(this.getClass());
        Integer result = null;
        try {
            result = channel.exec(application, data);
            return result;
        } finally {
            if (log.isDebugEnabled()) {
                String resLogger = result == null ? "FAILED" : "returned "
                        + result;
                log.debug("  Exec: " + application + "(" + data + ") : "
                        + resLogger);
            }
        }
    }

    /**
     * Dials out composing the dial app parameters from the method parameters
     * 
     * @param channelName
     *            Channel to use.
     * @param numberPrefix
     * @param number
     * @param channel
     * @param isFax
     *            TODO
     * @param options
     * @throws AgiException
     */
    protected void dial(String channelName, String numberPrefix, String number,
            Integer timeout, String extraOptions, AgiChannel channel,
            String optionsSeparator, boolean isFax, CallContext callContext)
            throws AgiException {
        String data = String.format("%s/%s%s%s%s", channelName, StringUtils
                .defaultString(numberPrefix), number, timeout == null ? ""
                : optionsSeparator + timeout, extraOptions == null ? ""
                : optionsSeparator + extraOptions);
        exec(isFax ? "T38Gateway" : "Dial", data, channel);
        callContext.setHangupCause(channel.getVariable("HANGUPCAUSE"));
    }

    protected void handleInboundDial(AgiChannel channel,
            CallContext callContext, String extraOptions, boolean isFax)
        throws AgiException {
        setAccountCode(channel, callContext.getCallingAccountCode());
        setCarrierCode(channel, callContext.getCalledCarrierCode());

        sendInitialCdr(callContext);
        addPChargingVectorHeader(callContext.getIcid(), channel);
        handleInboundLoadBalancedDial(channel, "",
                callContext.getEffectiveCalledNumber(),
                getInEstablishmentTimeout(), extraOptions, isFax,
                getGwChannelName(), callContext);
    }

    protected void handleInboundLoadBalancedDial(AgiChannel channel,
            String prefix, String number, int timeout, String extraOptions,
            boolean isFax, String[] gwChannelNames, CallContext callContext)
        throws AgiException {
        int gwNumber = gwChannelNames.length;
        String chosenGateway = null;
        if (gwNumber == 1) {
            chosenGateway = gwChannelNames[0];
        } else {
            int randIndex = getRandom().nextInt(gwNumber);
            chosenGateway = gwChannelNames[randIndex];
            if (log.isDebugEnabled()) {
                log.debug("Chosen gateway for load-balancing: " + chosenGateway);
            }
        }
        dial(chosenGateway, prefix, number, timeout, extraOptions, channel,
                ",", isFax, callContext);

        String dialStatus = channel.getVariable("DIALSTATUS");
        if ("CANCEL".equals(dialStatus)) {
            callContext.setHangupCause("0");
            if (log.isDebugEnabled()) {
                log.debug("Dial status is CANCEL, will not check hangup cause for fail-over");
            }
            return ;
        }
        HangupCause hangupCause = getHangupCause(callContext);
        if (hangupCause.getCode() == HangupCause.AST_CAUSE_SUBSCRIBER_ABSENT.getCode() ||
            hangupCause.getCode() == HangupCause.AST_CAUSE_NO_USER_RESPONSE.getCode() ||
            hangupCause.getCode() == HangupCause.AST_CAUSE_FAILURE.getCode() ||
            hangupCause.getCode() == HangupCause.AST_CAUSE_FACILITY_REJECTED.getCode() ||
            hangupCause.getCode() == HangupCause.AST_CAUSE_DESTINATION_OUT_OF_ORDER.getCode() ||
            hangupCause.getCode() == HangupCause.AST_CAUSE_CONGESTION.getCode() ||
            hangupCause.getCode() == HangupCause.AST_CAUSE_RECOVERY_ON_TIMER_EXPIRE.getCode() ||
            hangupCause.getCode() == HangupCause.AST_CAUSE_PROTOCOL_ERROR.getCode()) {
            if (log.isDebugEnabled()) {
                log.debug("Hangup cause is " + hangupCause + ", trying fail-over");
            }
            if (gwNumber == 1) {
                if (log.isDebugEnabled()) {
                    log.debug("Can not apply fail-over, this was the last gateway");
                }
                throw new NoGatewayAvailableException("No gateway available");
            } else {
                log.warn(chosenGateway + " failed. Choosing another gateway");
                gwChannelNames = (String[]) ArrayUtils.removeElement(gwChannelNames, chosenGateway);
                handleInboundLoadBalancedDial(channel, prefix, number, timeout,
                        extraOptions, isFax, gwChannelNames, callContext);
            }
        } // else no fail-over
    }

    protected void setCallerIdName(AgiChannel channel, String callerId)
            throws AgiException {
        exec("Set", "CALLERID(name)=" + callerId, channel);
    }

    protected void setCallerIdNum(AgiChannel channel, String callerId)
            throws AgiException {
        exec("Set", "CALLERID(num)=" + callerId, channel);
    }

    protected void setPrivacy(AgiChannel channel)
            throws AgiException {
        exec("SipAddHeader", "Privacy: id", channel);
    }

    protected String getCarrierCodeReq(AgiChannel channel) throws AgiException {
        String carrierCode = getCarrierCode(channel);
        if (StringUtils.isBlank(carrierCode)) {
            throw new RuntimeException(
                    "Unable to get carrier code from request");
        }
        return carrierCode;
    }

    // TODO : getSipHeader( ... )
    protected String getCarrierCode(AgiChannel channel) throws AgiException {
        String carrierCode = channel
          .getVariable("SIP_HEADER(X-CarrierCode)");
        return carrierCode;
    }

    /**
     * @return The account code from the request if present. If not present,
     *         account code from SIP header X-AccountCode if present. If not
     *         present either throws a RuntimeException
     * @throws AgiException
     *             if something goes wrong while retrieving the account code.
     * @throws IncomingAccountException
     *             if no account code was found.
     */
    protected String getAccountCodeReq(AgiRequest request, AgiChannel channel)
            throws AgiException {
        String accountCode = getAccountCode(request, channel);
        if (StringUtils.isBlank(accountCode)) {
            throw new IncomingAccountException(
                    "Unable to get account code from the request");
        }
        return accountCode;
    }

    protected String getAccountCode(AgiRequest request, AgiChannel channel)
            throws AgiException {
        String accountCode = request.getAccountCode();
        if (StringUtils.isBlank(accountCode)) {
            accountCode = channel
              .getVariable("SIP_HEADER(X-AccountCode)");
        }
        return accountCode;
    }

    /**
     * @return An initialized CDR with nodeName, complete and beginDate set.
     */
    protected CallContext initializeCdr() {
        CallContext cdr = new CallContext();

        cdr.setNode(getNodeName());
        cdr.setComplete(false);
        cdr.setBeginDate(new Date().getTime() / 1000);
        cdr.startTreatmentWatch();
        return cdr;
    }

    /**
     * Default implementation that returns null (used by inbound context's)
     * 
     * @param current
     *            channel
     * @return Returns the null value.
     * @see AbstractSigalAgi#handleCall(AgiRequest, AgiChannel, CallContext)
     */
    protected String getIcid(AgiChannel channel) {
      return null;
    }

    /**
     * Sets the account code
     * 
     * @param channel
     * @param carrier
     * @throws AgiException
     */
    protected void setAccountCode(AgiChannel channel, String accountCode)
            throws AgiException {
        exec("SipAddHeader", "X-AccountCode: " + accountCode, channel);
    }

    /**
     * Sets the carrier code
     * 
     * @param channel
     * @param carrier
     * @throws AgiException
     */
    protected void setCarrierCode(AgiChannel channel, String carrier)
            throws AgiException {
        exec("SipAddHeader", "X-CarrierCode: " + carrier, channel);
    }

    /**
     * Sets the P-Asserted-Identity header
     * 
     * @param channel
     * @param pai
     * @throws AgiException
     */
    protected void setPAssertedIdentity(AgiChannel channel, String pai)
            throws AgiException {
        exec("SipAddHeader", "P-Asserted-Identity: <tel:" + pai + ">", channel);
    }

    protected String getCalledAccountCodeFromSipDomain(AgiChannel channel)
            throws AgiException {
        String domain = channel.getFullVariable("${SIPDOMAIN}");

        Matcher matcher = SIP_DOMAIN_PATTERN.matcher(domain);
        if (matcher.matches()) {
            return matcher.group(1);
        }
        return null;
    }

    protected String getCalledAccountCodeFromSipDomainReq(AgiChannel channel)
            throws AgiException {
        String accountCode = getCalledAccountCodeFromSipDomain(channel);
        if (accountCode == null) {
            throw new OutgoingAccountException(
                    "Unable to get account code from SIP domain");
        }
        return accountCode;
    }

    protected HangupCause getHangupCause(CallContext callContext)
        throws AgiException {
        String hangupCause = StringUtils.defaultIfEmpty(
                callContext.getHangupCause(), "16");

        return HangupCause.getByCode(NumberUtils.parseNumber(hangupCause,
                Integer.class).intValue());
    }

    protected void doHangupAndSetEndCause(AgiChannel channel, CallContext callContext)
        throws AgiException {
        normalizeAndSetEndCause(callContext);
        String hangupCause = callContext.getHangupCause();

        if(hangupCause == null || StringUtils.isBlank(hangupCause) || hangupCause.equals("127")) {
          doHangup(channel, "19");
        } else {
          doHangup(channel, hangupCause);
        }
    }

    protected void doHangup(AgiChannel channel, HangupCause hangupCause)
        throws AgiException {
        channel.exec("Hangup", Integer.toString(hangupCause.getCode()));
    }

    protected void doHangup(AgiChannel channel, String hangupCause)
        throws AgiException {
        channel.exec("Hangup", hangupCause);
    }

    protected boolean isShortNumber(String number) {
        return shortNumberPattern.matcher(number).matches();
    }

    protected void normalizeAndSetEndCause(CallContext callContext) {
      String endCause = null;
      switch (Integer.parseInt(callContext.getHangupCause())) {
        case 0:
          endCause = "487/Cancelled";
          break;
        case 16:
          endCause = "200/Answered";
          break;
        case 21:
          endCause = "403/Forbidden";
          break;
        case 1:
        case 3:
          endCause = "404/NotFound";
          break;
        case 19:
          endCause = "480/TemporarilyUnavailable";
          break;
        case 127:
          endCause = "480/UnknownError";
          break;
        case 38:
          endCause = "500/Error";
          break;
        case 18:
          endCause = "408/RequestTimeout";
          break;
        case 41:
          endCause = "409/Conflict";
          break;
        case 22:
          endCause = "410/Gone";
          break;
        case 28:
          endCause = "484/addressIcomplete";
          break;
        case 17:
          endCause = "486/BusyHere";
          break;
        case 31:
          endCause = "480/LimitReached";
          break;
        case 34:
          endCause = "503/ServiceUnavailable";
          break;
        case 58:
          endCause = "488/NotAcceptableHere";
          break;
        case 29:
          endCause = "501/NotImplemented";
          break;
        case 27:
          endCause = "502/BadGateway";
          break;
        case 102:
          endCause = "504/GatewayTimeout";
          break;
        default:
          log.error("Unknown HangupCause: " + callContext.getHangupCause());
          endCause = "500/UnknownError";
      }
      callContext.setEndCause(endCause);
    }
}
