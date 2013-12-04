package com.initsys.sigal.agent.agi.ss7;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

import org.junit.Test;

import com.initsys.sigal.agent.agi.ss7.IsupInRdnis;

import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;

import org.easymock.EasyMock;
import org.easymock.IMocksControl;
import static org.easymock.EasyMock.eq;
import static org.easymock.EasyMock.expect;
import static org.easymock.EasyMock.matches;

public class IsupInRdnisTest {

	public static final String ISUP_IN_RDNIS_SAMPLE1 = "SMG003-CPC-010-"
			+ "RED-4444-002-0-1-8888-1-5-3-1-0-"
			+ "IAM-0D00010021010A00020907039080012020000A0703178082371"
			+ "0761D038090A303047D029181080180001EC08C9E1085DC45EF100100";
	public static final String iSUP_IN_RDNIS_SAMPLE1_WITHOUT_RED = "SMG003-CPC-010-"
			+ "IAM-0D00010021010A00020907039080012020000A0703178082371"
			+ "0761D038090A303047D029181080180001EC08C9E1085DC45EF100100";
	public static final String ISUP_IN_RDNIS_SAMPLE2 = "SMG003-CPC-010-"
			+ "GEN-001-333444-"
			+ "IAM-0D00010021010A00020907039080012020000A0703178082371"
			+ "0761D038090A303047D029181080180001EC08C9E1085DC45EF100100";

//	@Test
//	public void test000() {
//		System.err.println(ISUP_IN_RDNIS_SAMPLE1);
//		System.err.println(ISUP_IN_RDNIS_SAMPLE2);
//		System.err.println(IsupInRdnis.decode(ISUP_IN_RDNIS_SAMPLE1));
//		System.err.println(IsupInRdnis.decode(ISUP_IN_RDNIS_SAMPLE2));
//	}

	@Test
	public void testBizarre() {
    // TODO : refaire ce test
    //IsupInRdnis.decode("SMG003-CPC-010-RED--000-0-0-800009053-3-0-0-1-0");
	}
	
	@Test
	public void testEmpty() {
      // TODO : avant ce test verifiait que les autres args etaient nuls des mock except sur les set variable sur le channel
	    assertEquals("ordinary", new IsupInRdnis(IsupInRdnis.XF_DEFAULT_CPC).getCallingPartyIndicator());
      //assertEquals(null, new IsupInRdnis(IsupInRdnis.XF_DEFAULT_CPC).getCallerIdNumber());
	}
	
//	@Test
//	public void testFullEmpty() throws AgiException {
//		try {
//      IMocksControl mockCtrl = EasyMock.createStrictControl();
//      AgiChannel channel = mockCtrl.createMock(AgiChannel.class);
//			IsupInRdnis.decode(channel);
//			fail("should have thrown an IllegalArgumentException");
//		} catch (IllegalArgumentException e) {
//			// ok
//		}
//  }

	@Test
	public void testCpc() throws AgiException {
    IMocksControl mockCtrl = EasyMock.createStrictControl();
    AgiChannel channel = mockCtrl.createMock(AgiChannel.class);
    
		assertEquals("unknown", new IsupInRdnis("unknown").getCallingPartyIndicator());
		assertEquals("payphone", new IsupInRdnis("payphone").getCallingPartyIndicator());
		try {
      expect(IsupInRdnis.getSipHeader(channel, IsupInRdnis.XF_CPC)).andStubReturn("tutu");
      mockCtrl.replay();
			IsupInRdnis.decode(channel);
			fail("should have thrown an IllegalArgumentException");
		} catch (IllegalArgumentException e) {
      assertEquals("Unrecognized RDNIS, no CPC found but: 'tutu'", e.getMessage());
			// ok
		}
	}

	@Test
	public void loopback() {
    // TODO : refaire ce test
		//assertEquals(ISUP_IN_RDNIS_SAMPLE1, IsupInRdnis.decode(
		//		ISUP_IN_RDNIS_SAMPLE1).encode());
		//assertEquals(ISUP_IN_RDNIS_SAMPLE2, IsupInRdnis.decode(
		//		ISUP_IN_RDNIS_SAMPLE2).encode());
	}
}
