package com.initsys.sigal.agent.agi.isdn;


import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiRequest;
import org.asteriskjava.fastagi.AgiException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.initsys.sigal.agent.agi.AbstractSigalAgi;
import com.initsys.sigal.agent.agi.CallNormalizerImpl;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;

public abstract class AbstracIsdnAgi extends AbstractSigalAgi {

  /** logger */
  private static final Logger log = LoggerFactory.getLogger(AbstracIsdnAgi.class);

  private CallNormalizerImpl callNormalizer = new CallNormalizerImpl();

	public CallNormalizerImpl getCallNormalizer() {
		return callNormalizer;
	}

  protected void setCallerPres(AgiChannel channel, String pres)
    throws AgiException {
    exec("Set", "CALLERID(num-pres)=" + pres, channel);
  }

  protected boolean isPresentationProhibited(AgiRequest request,
      AgiChannel channel) throws NumberFormatException, AgiException {
    Logger log = LoggerFactory.getLogger(this.getClass());

    try {
      // TODO: transitional
      if ("Anonymous".equals(request.getCallerIdName())) {
        return true;
      }
      //TODO 1.9.1 supprimer
      /* // END: transitional */
      /* String pres = channel.getVariable("CALLERID(num-pres)"); */
      /* if (log.isDebugEnabled()) { */
      /*     log.debug("  Checking presentation: " + pres); */
      /* } */
      /* return pres.equals("prohib"); */
    } catch (NumberFormatException e) {
      return false;
    }
    return false;
  }
}
