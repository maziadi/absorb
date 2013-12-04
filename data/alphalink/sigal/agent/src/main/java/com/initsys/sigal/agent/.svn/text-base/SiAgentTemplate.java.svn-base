package com.initsys.sigal.agent;

import java.util.concurrent.TimeoutException;

import com.initsys.sigal.protocol.Si.SviRioQueryResponse;
import com.initsys.sigal.protocol.Si.SmsServerAck;

public interface SiAgentTemplate {
	/**
	 * 
	 * @param phoneNumber
	 *            Phone number to obtain RIO for.
	 * @return RIO information regarding the phone number.
	 * @throws TimeoutException
	 */
  public SviRioQueryResponse querySviRioByNumber(String phoneNumber)
			throws TimeoutException;

  public SmsServerAck sendRioBySms(SviRioQueryResponse sviRioResponse)
      throws TimeoutException;
}
