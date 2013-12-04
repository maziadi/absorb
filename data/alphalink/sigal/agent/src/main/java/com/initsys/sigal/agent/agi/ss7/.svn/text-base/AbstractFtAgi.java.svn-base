package com.initsys.sigal.agent.agi.ss7;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.live.HangupCause;

import com.initsys.sigal.agent.agi.AbstractSigalAgi;
import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.agent.agi.LimitReachedException;

import com.initsys.sigal.numbers.NatureOfAddress;
import com.initsys.sigal.numbers.PhoneAddress;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;

public abstract class AbstractFtAgi extends AbstractSigalAgi {

    /** logger */
    public static final Logger log = LoggerFactory.getLogger(AbstractFtAgi.class);

    /** Prefix to use for national NADI */
    public static final String NATIONAL_NADI = "003";

    /** Prefix to use for international NADI */
    public static final String INTERNATIONAL_NADI = "004";

    /** Prefix to use for special NADI */
    public static final String SPECIAL_NADI = "115";

    /** Prefix for calls under FT responsibility */
    private String ftChannelName;

    /** Prefix for calls under operator responsibility */
    private String opChannelName;

    /** Prefix for calls to NSG */
    private String nsgChannelName;

    /**
     * Dials out composing the dial app parameters from the method parameters
     * 
     * @param channelName
     *            Channel to use.
     * @param nadi
     * @param numberPrefix
     * @param number
     * @param options
     * @param channel
     * @throws AgiException
     */
    protected void dialOutbound(String channelName, String prefix,
            PhoneAddress address, Integer timeout, AgiChannel channel,
            CallContext callContext) throws AgiException {
        sendInitialCdr(callContext);
        IsupInRdnis.sipAddHeader(channel, IsupInRdnis.XF_CLD_NADI,
            address.getNadi()); // TODO : why ?
        dial(getNsgChannelName(),
                ((prefix == null ? "" // TODO verifier que le nadi est sette !?
                        : prefix)), address.getNumber() + "-g=" + channelName, timeout, null,
                channel, ",", false, callContext);

        /**
         * With qualify setting activated on peer
         * Asterisk set AST_CAUSE_SUBSCRIBER_ABSENT as HangupCause
         * In this case, if we get this HangupCause NSG is unreachable
         * We throws a RuntimeException to have Asterisk responding a 5xx error
         * to trigger the SCSCF's failover
         *
         **/
        if(HangupCause.AST_CAUSE_SUBSCRIBER_ABSENT == getHangupCause(callContext)) {
            throw new RuntimeException(
                    "Monitored peer temporarily unavailable");
        }
    }

    /**
     * 
     * @param address
     *            Number to deduce the channel name from.
     * @return Channel name to use.
     */
    protected String getChannelNameFromAddress(PhoneAddress address) {
        if (NatureOfAddress.SPECIAL == address.getNatureOfAddress()
                || (NatureOfAddress.NATIONAL == address.getNatureOfAddress() && address
                        .getNumber().startsWith("8"))) {
            return getFtChannelName();
        }
        return getOpChannelName();
    }

    public String getFtChannelName() {
        return ftChannelName;
    }

    /**
     * 
     * @param number
     *            Number for which we want a nadi
     * @return 3 digit NADI.
     */
    protected String getNadiFromE164Number(String number) {
        if (number.startsWith("33")) {
            if (number.length() < (2 + 9)) {
                return SPECIAL_NADI;
            } else if (number.startsWith("338")) {
                return SPECIAL_NADI;
            } else {
                return NATIONAL_NADI;
            }
        } else {
            return INTERNATIONAL_NADI;
        }
    }

    public String getOpChannelName() {
        return opChannelName;
    }

    public String getNsgChannelName() {
        return nsgChannelName;
    }

    protected IsupInRdnis parseIsup(AgiChannel channel) throws AgiException {
        String newIsupCPC = null;
        if (IsupInRdnis.getSipHeader(channel, IsupInRdnis.XF_CPC) == null) {
            log.warn("Empty ISUP CPC, creating a dummy with CPC of 010");
            newIsupCPC = IsupInRdnis.XF_DEFAULT_CPC;
        } else {
            try {
                return IsupInRdnis.decode(channel);
            } catch (IllegalArgumentException e) {
                log.warn("Invalid ISUP, creating a dummy with CPC of 010: " + e.getMessage());
                newIsupCPC = IsupInRdnis.getSipHeader(channel, IsupInRdnis.XF_CPC);
            }
        }
        Short calledNadi;
        try {
             calledNadi = Short.parseShort(IsupInRdnis.getSipHeader(channel, IsupInRdnis.XF_CLD_NADI));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid CLD-NADI");
        }
        Short callingNadi;
        try {
             callingNadi = Short.parseShort(IsupInRdnis.getSipHeader(channel, IsupInRdnis.XF_CLG_NADI));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid CLG-NADI");
        }
        Short callingPres;
        try {
            callingPres = Short.parseShort(IsupInRdnis.getSipHeader(channel, IsupInRdnis.XF_CLG_PRES));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid CLG-Pres");
        }
        return new IsupInRdnis(newIsupCPC, calledNadi, callingNadi, callingPres);
    }

    public void setFtChannelName(String ftPrefix) {
        this.ftChannelName = ftPrefix;
    }

    public void setOpChannelName(String opPrefix) {
        this.opChannelName = opPrefix;
    }

    public void setNsgChannelName(String nsgPrefix) {
        this.nsgChannelName = nsgPrefix;
    }

    public static boolean checkCounters(ExdbQueryResponse ex, boolean inbound) {
      if ((ex.hasMaxVnoCalls() && ex.hasVnoCallCount())
          && (ex.getMaxVnoCalls() <= ex.getVnoCallCount())) {
        throw new LimitReachedException("Vno call count reached its maximum ("
            + ex.getVnoCallCount() + "/" + ex.getMaxVnoCalls() +")");
          }
      if ((ex.hasMaxCalls() && ex.hasCallCount()) && (ex.getMaxCalls() <= ex.getCallCount())) {
        throw new LimitReachedException("Account call count reached its maximum ("
            + ex.getCallCount() + "/" + ex.getMaxCalls() +")");
      }
      if (inbound) {
        if ((ex.hasMaxInboundCalls() && ex.hasInboundCallCount())
            && (ex.getMaxInboundCalls() <= ex.getInboundCallCount())) {
          throw new LimitReachedException("Inbound account call count reached its maximum ("
              + ex.getInboundCallCount() + "/" + ex.getMaxInboundCalls() +")");
            }
      } else {
        if ((ex.hasMaxOutboundCalls() && ex.hasOutboundCallCount())
            && (ex.getMaxOutboundCalls() <= ex.getOutboundCallCount())) {
          throw new LimitReachedException("Outbound account call count reached its maximum ("
              + ex.getOutboundCallCount() + "/" + ex.getMaxOutboundCalls() +")");
            }
      }
      return true;
    }

    // TODO
    protected void setIsup(AgiChannel channel, IsupInRdnis isup)
        throws AgiException {
        isup.encode(channel);
    }

    protected static void setRedirectionInformation(PhoneAddress calledNumber,
            IsupInRdnis isup) {
        isup.setRedOriginalCalledNumber(calledNumber.getNumber());
        isup.setRedOriginalRedirectingReason((short)3);
        isup.setRedRedirectingIndicator((short) 3);
        isup.setRedRedirectingNumber(calledNumber.getNumber());
        isup.setRedRedirectingNumberNadi(calledNumber.getNatureOfAddress()
                .toShort());
        isup.setRedRedirectingNumberNumberPlan((short) 1);
        isup.setRedRedirectingNumberPresentation((short) 1);
        isup.setRedRedirectingReason((short)3);
        isup.setRedRedirectionCounter((short) 5);
        isup.setRedReserveNational((short) 0);
    }
}
