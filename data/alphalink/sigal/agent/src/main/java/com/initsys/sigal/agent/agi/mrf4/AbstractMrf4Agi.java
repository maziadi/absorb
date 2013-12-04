package com.initsys.sigal.agent.agi.mrf4;

import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;

import com.initsys.sigal.agent.agi.AbstractSigalAgi;
import com.initsys.sigal.agent.agi.CallNormalizerImpl;
import com.initsys.sigal.agent.agi.LimitReachedException;

import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;

public abstract class AbstractMrf4Agi extends AbstractSigalAgi {

  private CallNormalizerImpl callNormalizer = new CallNormalizerImpl();

  public CallNormalizerImpl getCallNormalizer() {
    return callNormalizer;
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
}
