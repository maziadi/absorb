package com.initsys.sigal.agent.agi;

import static org.easymock.EasyMock.expect;
import static org.easymock.EasyMock.replay;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertEquals;

import java.util.concurrent.TimeoutException;

import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;
import org.easymock.EasyMock;
import org.junit.Before;
import org.junit.Test;

public class AbstractSigalAgiTest {

	private AgiChannel channel;

	private AbstractSigalAgi agi;

	public AbstractSigalAgi getAgi() {
		return agi;
	}

	public AgiChannel getChannel() {
		return channel;
	}

	public void setAgi(AbstractSigalAgi agi) {
		this.agi = agi;
	}

	public void setChannel(AgiChannel channel) {
		this.channel = channel;
	}

	@Before
	public void setUp() {
		setChannel(EasyMock.createStrictMock(AgiChannel.class));
		setAgi(new AbstractSigalAgi() {

			@Override
			protected void prepareContext(AgiRequest request, AgiChannel channel,
					CallContext cdr) throws AgiException {
				// empty
			}

			@Override
			public void handleCall(AgiRequest request, AgiChannel channel,
					CallContext cdr) throws AgiException, TimeoutException {
				// empty
			}
		});
	}

	@Test
	public void testSipUriWithAccountCode() throws AgiException {
		expect(getChannel().getFullVariable("${SIPDOMAIN}")).andReturn(
				"0990000000000.mrf-1.sip.openvno.net");
		replay(getChannel());
		assertEquals("0990000000000", getAgi().getCalledAccountCodeFromSipDomain(
				getChannel()));
	}

	@Test
	public void testSipUriWithIncorrectAccountCode() throws AgiException {
		expect(getChannel().getFullVariable("${SIPDOMAIN}")).andReturn(
				"099001.mgcf-3.sip.openvno.net");
		replay(getChannel());
		assertNull(getAgi().getCalledAccountCodeFromSipDomain(getChannel()));
	}

	@Test
	public void testSipUri() throws AgiException {
		expect(getChannel().getFullVariable("${SIPDOMAIN}")).andReturn(
				"192.168.1.1");
		replay(getChannel());
		assertNull(getAgi().getCalledAccountCodeFromSipDomain(getChannel()));
	}

}
