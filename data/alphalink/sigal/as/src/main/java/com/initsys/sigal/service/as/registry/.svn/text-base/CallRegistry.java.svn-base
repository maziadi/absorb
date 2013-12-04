package com.initsys.sigal.service.as.registry;

public interface CallRegistry {

    public void addCall(CallRegistryCdr cdr);

    public boolean removeCall(CallRegistryCdr cdr);

    /**
     * 
     * @param vnoName
     *            Name of the VNO.
     * @return Number of currently active inboundCalls for the given VNO.
     */
    public int getCountByVno(String vnoName);

    /**
     * @param accountCode
     *            Account code to count for.
     * @return Number of currently active inboundCalls for the given account
     *         code.
     */
    public int getCountByAccount(String accountCode);

    /**
     * @param accountCode
     *            Account code to count for.
     * @return Number of currently active outbound inboundCalls for the given
     *         account code.
     */
    public int getOutboundCountByAccount(String accountCode);

    /**
     * @param accountCode
     *            Account code to count for.
     * @return Number of currently active inbound inboundCalls for the given
     *         account code.
     */
    public int getInboundCountByAccount(String accountCode);

    /**
     * @param maxCallDuration
     *            max allowed call duration in seconds.
     */
    public void periodicCleanup(long maxCallDuration);

}
