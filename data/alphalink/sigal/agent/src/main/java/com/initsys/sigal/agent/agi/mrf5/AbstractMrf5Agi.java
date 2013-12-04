package com.initsys.sigal.agent.agi.mrf5;

import org.apache.commons.lang.StringUtils;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;

import com.initsys.sigal.agent.agi.AbstractSigalAgi;
import com.initsys.sigal.agent.agi.CallContext;
import com.initsys.sigal.agent.agi.CallNormalizerImpl;
import com.initsys.sigal.agent.agi.LimitReachedException;

import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;

public abstract class AbstractMrf5Agi extends AbstractSigalAgi {

    private CallNormalizerImpl callNormalizer = new CallNormalizerImpl();

    /**
     * Composes the and calls the Dial command.
     * 
     * @param lidbResponse
     * @param accountCode
     * @param channel
     * @param number
     * @throws AgiException
     */
    protected void dialOutbound(LidbQueryResponse lidbResponse,
            AgiChannel channel, String number, int answerTimeout,
            CallContext callContext) throws AgiException {
        boolean isFax = lidbResponse.hasFax() && lidbResponse.getFax();

        if (! lidbResponse.getTrunk()) {
            number = callContext.getCalledAccountCode();
        }

        addPChargingVectorHeader(callContext.getIcid(), channel);
        dial(getGwChannelName()[0], "", number, answerTimeout, null, channel,
                ",", isFax, callContext);
    }

    public static boolean checkCounters(LidbQueryResponse li, boolean inbound) {
      if ((li.hasMaxVnoCalls() && li.hasVnoCallCount())
          && (li.getMaxVnoCalls() <= li.getVnoCallCount())) {
        throw new LimitReachedException("Vno call count reached its maximum ("
            + li.getVnoCallCount() + "/" + li.getMaxVnoCalls() +")");
          }
      if ((li.hasMaxCalls() && li.hasCallCount())
          && (li.getMaxCalls() <= li.getCallCount())) {
        throw new LimitReachedException("Account call count reached its maximum ("
            + li.getCallCount() + "/" + li.getMaxCalls() +")");
          }
      if (inbound) {
        if (li.hasMaxInboundCalls() && li.hasInboundCallCount()
            && (li.getMaxInboundCalls() <= li.getInboundCallCount())) {
          throw new LimitReachedException("Inbound account call count reached its maximum ("
              + li.getInboundCallCount() + "/" + li.getMaxInboundCalls() +")");
            }
      } else {
        if (li.hasMaxOutboundCalls() && li.hasOutboundCallCount()
            && (li.getMaxOutboundCalls() <= li.getOutboundCallCount())) {
          throw new LimitReachedException("Outbound account call count reached its maximum ("
              + li.getOutboundCallCount() + "/" + li.getMaxOutboundCalls() +")");
            }
      }
      return true;
    }

    public CallNormalizerImpl getCallNormalizer() {
        return callNormalizer;
    }
}
