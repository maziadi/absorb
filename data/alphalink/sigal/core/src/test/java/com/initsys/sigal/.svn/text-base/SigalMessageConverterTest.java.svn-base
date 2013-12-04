package com.initsys.sigal;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

import com.google.protobuf.Message;
import com.initsys.sigal.protocol.Sigal.EmdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.ExdbUpdateResponse;
import com.initsys.sigal.protocol.Sigal.LidbUpdateRequest;
import com.initsys.sigal.protocol.Sigal.NpdbQueryResponse;

public class SigalMessageConverterTest {

	@Test
	public void messageTypeConversion() throws ClassNotFoundException {
		assertEquals(EmdbQueryRequest.class, SigalMessageConverter
				.messageTypeAsClass("EMDB.QUERY.REQUEST"));
		assertEquals(NpdbQueryResponse.class, SigalMessageConverter
				.messageTypeAsClass("NPDB.QUERY.RESPONSE"));
		assertEquals(LidbUpdateRequest.class, SigalMessageConverter
				.messageTypeAsClass("LIDB.UPDATE.REQUEST"));
		assertEquals(ExdbUpdateResponse.class, SigalMessageConverter
				.messageTypeAsClass("EXDB.UPDATE.RESPONSE"));
	}

	@Test
	public void trivialEncodingDecodingTest() {
		Message src = EmdbQueryRequest.newBuilder().setVersion(1).setNumber(
				"123").setInseeCode("00999").build();

		Message res = (EmdbQueryRequest) SigalMessageConverter
				.parseMessageForType("EMDB.QUERY.REQUEST", src.toByteArray());

		assertEquals(src, res);

	}
}
