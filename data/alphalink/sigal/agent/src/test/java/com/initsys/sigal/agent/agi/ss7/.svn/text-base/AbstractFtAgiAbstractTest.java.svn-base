package com.initsys.sigal.agent.agi.ss7;

import static org.easymock.EasyMock.expect;

import org.asteriskjava.fastagi.AgiException;

import com.initsys.sigal.agent.agi.SigalAgiAbstractTest;
import com.initsys.sigal.agent.agi.ss7.AbstractFtAgi;

public abstract class AbstractFtAgiAbstractTest<A extends AbstractFtAgi> extends
		SigalAgiAbstractTest<A> {


	public void setUp() throws Exception {
		super.setUp();
		getAgi().setOutEstablishmentTimeout(120);
		getAgi().setInEstablishmentTimeout(121);
        String[] gwChannelName = new String[] {"SIP"};
		getAgi().setGwChannelName(gwChannelName);
		getAgi().setFtChannelName("FT");
		getAgi().setOpChannelName("ORT");
    getAgi().setNsgChannelName("SIP/NSG");
	}

	protected void expectDialWithNadi(String channelName, String nadi,
			String number, String options) throws AgiException {
    expectSipAddHeader(IsupInRdnis.XF_CPC, "ordinary");// unused by smg but by me for redirection & porta
    expectSipAddHeader(IsupInRdnis.XF_CLD_NADI, nadi);
		//expect(getChannel().exec("SetTransferCapability", "3K1AUDIO")) // should be set by smg
		//		.andReturn(0);
		expectDial("SIP/NSG", number + "-g=" + channelName, options, ",", null);
	}

	protected void  expectSipAddHeader(String key, String value) throws AgiException {
    expect(getChannel().exec("SipAddHeader", key + ": " + value)).andReturn(
				0);
	}

	protected void stageCallingPres(String value) throws AgiException {
		expect(getChannel().getVariable("CALLINGPRES")).andStubReturn(value);
	}
}
