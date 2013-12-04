package com.initsys.sigal.service.as.registry;

import java.util.Date;

import org.apache.commons.lang.builder.EqualsBuilder;
import org.apache.commons.lang.builder.HashCodeBuilder;

public class CallRegistryCdr {

    private String icid;

    private String vnoName;

    private String accountCode;

    private Boolean inbound;

    private Date beginDate;

    public Date getBeginDate() {
        return beginDate;
    }

    public void setBeginDate(Date beginDuration) {
        this.beginDate = beginDuration;
    }

    public Boolean getInbound() {
        return inbound;
    }

    public void setInbound(Boolean inbound) {
        this.inbound = inbound;
    }

    public String getAccountCode() {
        return accountCode;
    }

    public void setAccountCode(String accountCode) {
        this.accountCode = accountCode;
    }

    public String getVnoName() {
        return vnoName;
    }

    public void setVnoName(String vno) {
        this.vnoName = vno;
    }

    public CallRegistryCdr() {
        // empty
    }

    public CallRegistryCdr(String icid, String vno, String account,
            Boolean inbound, Date beginDate) {
        setIcid(icid);
        setVnoName(vno);
        setAccountCode(account);
        setInbound(inbound);
        setBeginDate(beginDate);
    }

    public String getIcid() {
        return icid;
    }

    public void setIcid(String icid) {
        this.icid = icid;
    }

    @Override
    public String toString() {
        return String
                .format(
                        "CallRegistryCdr[%s]: vnoName = %s, accountCode = %s, inbound = %s, beginDate = %tT",
                        getIcid(), getVnoName(), getAccountCode(),
                        getInbound(), getBeginDate());
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CallRegistryCdr)) {
            return false;
        }
        CallRegistryCdr other = (CallRegistryCdr) obj;
        return new EqualsBuilder().append(getIcid(), other.getIcid()).append(
                getAccountCode(), other.getAccountCode()).append(getInbound(),
                other.getInbound()).append(getVnoName(), other.getVnoName())
                .isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder().append(getIcid()).append(getAccountCode())
                .append(getInbound()).append(getVnoName()).hashCode();
    }
}
