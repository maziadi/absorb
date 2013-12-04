package com.initsys.sigal.agent;

import java.util.concurrent.TimeoutException;

import com.initsys.sigal.protocol.Sigal.Cdr;
import com.initsys.sigal.protocol.Sigal.EmdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.MlidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.NpdbQueryResponse;

public interface SigalAgentTemplate {
	/**
	 * 
	 * @param phoneNumber
	 *            Phone number to check portability for.
	 * @return A portability response.
	 * @throws TimeoutException
	 */
	public NpdbQueryResponse queryPorted(final String phoneNumber)
			throws TimeoutException;

	/**
	 * 
	 * @param phoneNumber
	 *            Phone number to obtain line information for.
	 * @return Line information regarding the phone number.
	 * @throws TimeoutException
	 */
	public LidbQueryResponse queryLineInfoByNumber(String phoneNumber)
			throws TimeoutException;

	/**
	 * 
	 * @param phoneNumber
	 *            Phone number to obtain mobile line information for.
	 * @return Mobile Line information regarding the phone number.
	 * @throws TimeoutException
	 */
	public MlidbQueryResponse queryMobileLineInfoByMsisdn(String phoneNumber)
			throws TimeoutException;

	/**
	 * 
	 * @param phoneNumber
	 * @param inseeCode
	 * @return
	 * @throws TimeoutException
	 */
	public EmdbQueryResponse queryEmergency(String phoneNumber, String inseeCode)
			throws TimeoutException;

	/**
	 * 
	 * @param accountCode
	 * @return
	 * @throws TimeoutException
	 */
	public LidbQueryResponse queryLineInfoByAccountCode(String accountCode)
			throws TimeoutException;

	/**
	 * 
	 * @param cdr
	 */
	public void sendCdrMessage(Cdr cdr);

	/**
	 * 
	 * @param asccountCode
	 * @return
	 * @throws TimeoutException
	 */
	public ExdbQueryResponse queryIntercoByAccountCode(String accountCode)
			throws TimeoutException;
}
