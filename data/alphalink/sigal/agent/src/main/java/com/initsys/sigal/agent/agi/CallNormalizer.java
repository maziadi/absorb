package com.initsys.sigal.agent.agi;

public interface CallNormalizer {

	public void normalizeInbound(CallContext cdr, String inboundNumberingPlan,
			String defaulCallingNumber);

	public void normalizeOutbound(CallContext cdr, String outboundNumberingPlan);

}
