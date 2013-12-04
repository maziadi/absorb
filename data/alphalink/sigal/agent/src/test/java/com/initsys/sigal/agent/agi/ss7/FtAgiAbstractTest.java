package com.initsys.sigal.agent.agi.ss7;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.util.concurrent.TimeoutException;

import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;
import org.junit.Before;
import org.junit.Test;

import com.initsys.sigal.agent.agi.CallContext;

import com.initsys.sigal.agent.agi.SigalAgiAbstractTest;
import com.initsys.sigal.agent.agi.LimitReachedException;
import com.initsys.sigal.numbers.NatureOfAddress;
import com.initsys.sigal.numbers.PhoneAddress;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;

public class FtAgiAbstractTest<A extends AbstractFtAgi> extends
		SigalAgiAbstractTest<A> {

	@SuppressWarnings("unchecked")
	@Before
	public void setUp() {
		setAgi((A) new AbstractFtAgi() {

			@Override
			protected void prepareContext(AgiRequest request, AgiChannel channel,
					CallContext cdr) throws AgiException {
				// TODO Auto-generated method stub

			}

			@Override
			public void handleCall(AgiRequest request, AgiChannel channel,
					CallContext cdr) throws AgiException, TimeoutException {
			}

		});
		getAgi().setFtChannelName("FT");
		getAgi().setOpChannelName("ORT");
	}

	@Test
	public void testGetNadiFromE164Number() {
		assertEquals("003", getAgi().getNadiFromE164Number("33312345678"));
		assertEquals("003", getAgi().getNadiFromE164Number("33112345678"));
		assertEquals("003", getAgi().getNadiFromE164Number("33912345678"));
		assertEquals("004", getAgi().getNadiFromE164Number("11234"));
		assertEquals("004", getAgi().getNadiFromE164Number("4912345678"));
		assertEquals("004", getAgi().getNadiFromE164Number("36123456"));
		assertEquals("004", getAgi().getNadiFromE164Number("361234567890"));
		assertEquals("115", getAgi().getNadiFromE164Number("331014"));
		assertEquals("115", getAgi().getNadiFromE164Number("333615"));
		assertEquals("115", getAgi().getNadiFromE164Number("33812345678"));
	}

	@Test
	public void testgetChannelNameFromAddress() {
		assertEquals("ORT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("312345678", NatureOfAddress.NATIONAL)));
		assertEquals("ORT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("33112345678", NatureOfAddress.NATIONAL)));
		assertEquals("ORT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("33912345678", NatureOfAddress.NATIONAL)));
		assertEquals("ORT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("11234", NatureOfAddress.INTERNATIONAL)));
		assertEquals("ORT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("4912345678", NatureOfAddress.INTERNATIONAL)));
		assertEquals("ORT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("36123456", NatureOfAddress.INTERNATIONAL)));
		assertEquals("ORT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("361234567890", NatureOfAddress.NATIONAL)));
		assertEquals("FT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("331014", NatureOfAddress.SPECIAL)));
		assertEquals("FT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("333615", NatureOfAddress.SPECIAL)));
		assertEquals("FT", getAgi().getChannelNameFromAddress(
				new PhoneAddress("33812345678", NatureOfAddress.SPECIAL)));
	}

  private ExdbQueryResponse createExForCount(Integer maxVnoCalls, Integer vnoCallCount, Integer maxCalls,
      Integer callCount, Integer maxInboundCalls, Integer inboundCalls,
      Integer maxOutboundCalls, Integer outboundCalls) {
    ExdbQueryResponse.Builder builder = ExdbQueryResponse.newBuilder()
      .setVersion(1);
    if (maxVnoCalls != null) {
      builder.setMaxVnoCalls(maxVnoCalls);
    }
    if (vnoCallCount != null) {
      builder.setVnoCallCount(vnoCallCount);
    }
    if (maxCalls != null) {
      builder.setMaxCalls(maxCalls);
    }
    if (callCount != null) {
      builder.setCallCount(callCount);
    }
    if (maxInboundCalls != null) {
      builder.setMaxInboundCalls(maxInboundCalls);
    }
    if (inboundCalls != null) {
      builder.setInboundCallCount(inboundCalls);
    }
    if (maxOutboundCalls != null) {
      builder.setMaxOutboundCalls(maxOutboundCalls);
    }
    if (outboundCalls != null) {
      builder.setOutboundCallCount(outboundCalls);
    }
    return builder.build();
  }

  public void assertTrueCounters(Integer maxVnoCalls, Integer vnoCallCount, Integer maxCalls, Integer callCount,
      Integer maxInboundCalls, Integer inboundCalls,
      Integer maxOutboundCalls, Integer outboundCalls, boolean inbound) {
    assertTrue(AbstractFtAgi.checkCounters(createExForCount(maxVnoCalls, vnoCallCount, maxCalls,
            callCount, maxInboundCalls, inboundCalls, maxOutboundCalls,
            outboundCalls), inbound));
  }

  public void assertExceptionCounters(Integer maxVnoCalls, Integer vnoCallCount, Integer maxCalls, Integer callCount,
      Integer maxInboundCalls, Integer inboundCalls,
      Integer maxOutboundCalls, Integer outboundCalls, boolean inbound) {
    try {
      AbstractFtAgi.checkCounters(createExForCount(maxVnoCalls, vnoCallCount, maxCalls,
            callCount, maxInboundCalls, inboundCalls, maxOutboundCalls,
            outboundCalls), inbound);
      fail("Should have thrown a LimitReachedException");
    } catch (Exception e) {
      assertTrue(e instanceof LimitReachedException);
    }
  }

  @Test
  public void testCounters() {
    assertTrueCounters(null, null, null, null, null, null, null, null, true);

    assertTrueCounters(1, null, null, null, null, null, null, null, true);
    assertTrueCounters(null, 1, null, null, null, null, null, null, true);
    assertExceptionCounters(1, 1, null, null, null, null, null, null, true);
    assertTrueCounters(1, 0, null, null, null, null, null, null, true);
    assertTrueCounters(2, 1, null, null, null, null, null, null, true);
    assertExceptionCounters(1, 2, null, null, null, null, null, null, true);
    assertExceptionCounters(1, 2, null, null, null, null, null, null, false);

    assertTrueCounters(null, null, 1, null, null, null, null, null, true);
    assertTrueCounters(null, null, null, 1, null, null, null, null, true);
    assertExceptionCounters(null, null, 1, 1, null, null, null, null, true);
    assertTrueCounters(null, null, 1, 0, null, null, null, null, true);
    assertExceptionCounters(null, null, 1, 2, null, null, null, null, true);
    assertExceptionCounters(null, null, 1, 2, null, null, null, null, false);

    assertTrueCounters(null, null, null, null, 1, null, null, null, true);
    assertTrueCounters(null, null, null, null, null, 1, null, null, true);
    assertExceptionCounters(null, null, null, null, 11, 11, null, null, true);
    assertTrueCounters(null, null, null, null, 9, 8, null, null, true);
    assertExceptionCounters(null, null, null, null, 19, 20, null, null, true);
    assertTrueCounters(null, null, null, null, 19, 20, null, null, false);

    assertTrueCounters(null, null, null, null, null, null, 100, null, true);
    assertTrueCounters(null, null, null, null, null, null, null, 167, true);
    assertTrueCounters(null, null, null, null, null, null, 143, 142, true);
    assertTrueCounters(null, null, null, null, null, null, 78, 32, true);
    assertTrueCounters(null, null, null, null, null, null, 2, 1893, true);
    assertExceptionCounters(null, null, null, null, null, null, 2, 1893, false);

    assertTrueCounters(11, 10, 11, 10, 11, 10, 11, 10, true);
    assertExceptionCounters(10, 11, 10, 10, 10, 10, 10, 10, true);
    assertExceptionCounters(10, 10, 10, 10, 10, 10, 10, 10, true);
    assertExceptionCounters(11, 10, 10, 11, 10, 10, 10, 10, true);
    assertExceptionCounters(11, 10, 10, 10, 10, 11, 10, 10, true);
    assertExceptionCounters(11, 10, 10, 11, 10, 10, 10, 10, true);
    assertExceptionCounters(11, 10, 10, 10, 10, 11, 10, 10, true);
    assertExceptionCounters(11, 10, 10, 10, 10, 10, 10, 11, true);
    assertExceptionCounters(11, 10, 10, 11, 10, 11, 10, 11, true);

    assertTrueCounters(11, 10, 11, 10, 11, 10, 10, 11, true);
    assertTrueCounters(11, 10, 11, 10, 10, 11, 11, 10, false);
  }


}
