package com.initsys.sigal.agent.agi.ss7;

import java.util.concurrent.TimeoutException;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;
import org.asteriskjava.live.HangupCause;

import com.initsys.sigal.agent.agi.LimitReachedException;
import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.agent.agi.IdentityException;
import com.initsys.sigal.agent.agi.SipHeaderIcidExtractor;
import com.initsys.sigal.numbers.PhoneAddress;
import com.initsys.sigal.protocol.Sigal.NpdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.vno.VnoConstants;

import static org.apache.commons.lang.StringUtils.defaultString;
import static org.apache.commons.lang.StringUtils.stripStart;
import static org.apache.commons.lang.StringUtils.stripEnd;
import static org.apache.commons.lang.StringUtils.isBlank;

public class Ss7OutboundAgi extends AbstractFtAgi {

  /** logger */
  static final Logger log = LoggerFactory.getLogger(Ss7OutboundAgi.class);

  @Override
  protected void prepareContext(AgiRequest request, AgiChannel channel,
      CallContext callContext) throws AgiException {
    callContext.setCallingNetwork(VnoConstants.INTERNAL_NETWORK);
    callContext.setCalledNetwork(VnoConstants.EXTERNAL_NETWORK);
    callContext.setBothCarrierCodes(getCarrierCodeReq(channel));
    callContext.setCallingAccountCode(getAccountCodeReq(request, channel));
    callContext.setCalledNumber(request.getExtension());
    callContext
      .setCalledAccountCode(getCalledAccountCodeFromSipDomainReq(channel));

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

  @Override
  public void handleCall(AgiRequest request, AgiChannel channel,
      CallContext callContext) throws AgiException, TimeoutException {
    IsupInRdnis isup = new IsupInRdnis(IsupInRdnis.XF_DEFAULT_CPC);
    String identityValue = defaultString(channel
        .getVariable("SIP_HEADER(P-Asserted-Identity)"));
    boolean privacy = defaultString(
        channel.getVariable("SIP_HEADER(Privacy)")).equals("id");

    // Pour envoyer le prefix de porta sortante si porta sortante
    NpdbQueryResponse npdbResponse = getTemplate().queryPorted(
        callContext.getCalledNumber());

    // gestion de l'identite
    identityValue = stripEnd(stripStart(identityValue, "<tel:+"), ">");
    if(isBlank(identityValue)) {
      throw new IdentityException("Missing identity value");
    }

    PhoneAddress identityAddress = PhoneAddress.fromE164(identityValue,
          FRANCE_E164_PREFIX);
    callContext.setCallingIdentityNumber(identityValue);
    callContext.setEffectiveCallingIdentityNumber(identityAddress.getNumber());
    isup.setCallingNadi(Short.valueOf(identityAddress.getCallingNadi()));

    PhoneAddress calledAddress = PhoneAddress.fromE164(callContext
        .getCalledNumber(), FRANCE_E164_PREFIX);
    callContext.setEffectiveCalledNumber(calledAddress.getNumber());

    setCallerIdNum(channel, callContext.getEffectiveCallingIdentityNumber());

    // gestion privacy
    if (privacy) {
      callContext.setPrivacy(true);
    }
    isup.setCallingPres(callContext.getPrivacy() ? (short)1 : (short)0);
    isup.setCallingScreen((short)3);

    // gestion du generic number
    callContext.setCallingNumber(StringUtils.stripStart(request
          .getCallerIdNumber(), "+"));
    PhoneAddress callerAddress = PhoneAddress.fromE164(callContext
        .getCallingNumber(), FRANCE_E164_PREFIX);
    callContext.setEffectiveCallingNumber(callerAddress.getNumber());
    callContext.setCallingName(defaultString(request.getCallerIdName()));

    if(!(isBlank(callContext.getCallingNumber()) ||
        callContext.getCallingNumber().equals("anonymous"))) {
      isup.setGenNumberQualifierIndicator((short)6);
      isup.setGenNumberPlanIndicator((short)1);
      isup.setGenAddressScreeningIndicator((short)0);
      isup.setGenAddressPresentationIndicator(callContext.getPrivacy() ? (short)1 : (short)0);
      isup.setGenNadi(Short.valueOf(callerAddress.getCallingNadi()));
      isup.setGenNumber(callerAddress.getNumber());
    }

    // gestion des redirections
    String redirectingNumber = channel
      .getVariable("SIP_HEADER(X-RedirectingNumber)");

    if (!StringUtils.isBlank(redirectingNumber)) {
      if (log.isDebugEnabled()) {
        log.debug("Handling call as redirected from '"
            + redirectingNumber + "'");
      }
      PhoneAddress redirectingAddress = PhoneAddress.fromE164(
          redirectingNumber, FRANCE_E164_PREFIX);

      setRedirectionInformation(redirectingAddress, isup);
    }

    // query exdb
    ExdbQueryResponse exdbResponse = getTemplate()
      .queryIntercoByAccountCode(callContext.getCalledAccountCode());

    // add X-FreeTDM (CPC, Pres, Screen, GN, RDNIS)
    setIsup(channel, isup);

    if (callContext.getCalledCarrierCode().equals("emergency")) {
      dialOutbound(getChannelNameFromAddress(calledAddress), npdbResponse
          .getPrefix(), calledAddress, getOutEstablishmentTimeout(),
          channel, callContext);
    } else {
      if (!checkCounters(exdbResponse, false)) {
        // Unreachable block due to checkCounters implementation
        throw new LimitReachedException("Limit reached : a counter has reached its max value");
      } else if (exdbResponse.getLocked()) {
        throw new LimitReachedException("Account is locked");
      } else {
        dialOutbound(getChannelNameFromAddress(calledAddress), npdbResponse
            .getPrefix(), calledAddress, getOutEstablishmentTimeout(),
            channel, callContext);
      }
    }
  }
}
