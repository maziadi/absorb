package com.initsys.sigal.protocol;

import com.initsys.sigal.protocol.Sigal.ResponseStatus;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;

public class SigalProtocolHelper {

	public static ResponseStatus buildStatus(ResponseStatusCode code, String msg) {
		ResponseStatus.Builder builder = ResponseStatus.newBuilder().setCode(
				code);
		if (msg != null) {
			builder.setMessage(msg);
		}

		return builder.build();
	}
}
