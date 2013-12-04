package com.initsys.sigal.agent.agi;

import java.util.Date;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.time.StopWatch;

import com.initsys.sigal.protocol.Sigal.CallAddress;
import com.initsys.sigal.protocol.Sigal.AddressPresentation;
import com.initsys.sigal.protocol.Sigal.Cdr;

/**
 * Helper class for handling CdrMessage construction.
 */
public class CallContext {

    private Cdr.Builder cdr;

    private CallAddress.Builder called;

    private CallAddress.Builder calling;

    private String redirectedFrom;

    private StopWatch treatmentWatch;

    private String dialStatus;

    private String hangupCause;

    public String getRedirectedFrom() {
        return redirectedFrom;
    }

    public void setRedirectedFrom(String redirectedFrom) {
        this.redirectedFrom = redirectedFrom;
    }

    public boolean isRedirected() {
        return StringUtils.isNotBlank(getRedirectedFrom());
    }

    public String getEffectiveCallingNumber() {
        return this.calling.getEffectiveNumber();
    }

    public CallContext setEffectiveCallingNumber(String effectiveCallingNumber) {
        this.calling.setEffectiveNumber(effectiveCallingNumber);
        return this;
    }

    public void stopTreatmentWatch() {
        this.treatmentWatch.stop();
    }

    public void startTreatmentWatch() {
        this.treatmentWatch.start();
    }

    public int getTreatmentDuration() {
        return (int) this.treatmentWatch.getTime() / 1000;
    }

    public CallContext() {
        this.treatmentWatch = new StopWatch();
        this.cdr = Cdr.newBuilder();
        this.called = CallAddress.newBuilder();
        this.calling = CallAddress.newBuilder();

        this.cdr.setVersion(1);
        this.called.setVersion(1);
        this.calling.setVersion(1);
    }

    public Cdr build() {
        this.cdr.setCalled(this.called);
        this.cdr.setCalling(this.calling);
        return this.cdr.build();
    }

    public CallContext clone() {
        CallContext copy = new CallContext();
        copy.cdr = this.cdr.clone();
        copy.called = this.called.clone();
        copy.calling = this.calling.clone();

        return copy;
    }

    public void replace(CallContext context) {
        this.cdr = context.cdr.clone();
        this.called = context.called.clone();
        this.calling = context.calling.clone();
    }

    public void complete() {
        setComplete(true);
        computeDuration();
    }

    public void computeDuration() {
        if (!cdr.hasBeginDate()) {
            throw new IllegalStateException(
                    "Cannot compute duration if beginDate is not present");
        }
        setDuration((int) (new Date().getTime() / 1000 - getBeginDate()));
    }

    public boolean getAnswered() {
        return cdr.getAnswered();
    }

    public long getBeginDate() {
        return cdr.getBeginDate();
    }

    public boolean hasBillableDuration() {
        return cdr.hasBillableDuration();
    }

    public int getBillableDuration() {
        return cdr.getBillableDuration();
    }

    public String getCalledAccountCode() {
        return this.called.getAccountCode();
    }

    public String getCalledCarrierCode() {
        return this.called.getCarrierCode();
    }

    public String getCalledName() {
        return this.called.getName();
    }

    public String getCalledNumber() {
        return this.called.getNumber();
    }

    public String getCallingAccountCode() {
        return this.calling.getAccountCode();
    }

    public String getCallingCarrierCode() {
        return this.calling.getCarrierCode();
    }

    public String getCallingName() {
        return this.calling.getName();
    }

    public String getCallingNumber() {
        return this.calling.getNumber();
    }

    public boolean getComplete() {
        return cdr.getComplete();
    }

    public int getDuration() {
        return cdr.getDuration();
    }

    public String getEffectiveCalledNumber() {
        return this.called.getEffectiveNumber();
    }

    public String getCallingIdentityNumber() {
        return this.calling.getIdentityNumber();
    }

    public CallContext setCallingIdentityNumber(String callingIdentityNumber) {
        this.calling.setIdentityNumber(callingIdentityNumber);
        return this;
    }

    public String getEffectiveCallingIdentityNumber() {
        return this.calling.getEffectiveIdentityNumber();
    }

    public CallContext setEffectiveCallingIdentityNumber(String effectiveCallingIdentityNumber) {
        this.calling.setEffectiveIdentityNumber(effectiveCallingIdentityNumber);
        return this;
    }

    public boolean hasEndCause() {
        return cdr.hasEndCause();
    }

    public String getEndCause() {
        return cdr.getEndCause();
    }

    public String getIcid() {
        return cdr.getIcid();
    }

    public String getMessage() {
        return this.cdr.getMessage();
    }

    public String getNode() {
        return cdr.getNode();
    }

    public CallContext setAnswered(boolean value) {
        cdr.setAnswered(value);
        return this;
    }

    public CallContext setBeginDate(long value) {
        cdr.setBeginDate(value);
        return this;
    }

    public CallContext setBillableDuration(int value) {
        cdr.setBillableDuration(value);
        return this;
    }

    public CallContext setCalled(
            com.initsys.sigal.protocol.Sigal.CallAddress.Builder builderForValue) {
        cdr.setCalled(builderForValue);
        return this;
    }

    public CallContext setCalledAccountCode(String accountCode) {
        this.called.setAccountCode(accountCode);
        return this;
    }

    public CallContext setCalledCarrierCode(String carrierCode) {
        this.called.setCarrierCode(carrierCode);
        return this;
    }

    /**
     * 
     * @param carrierCode
     * @return current call context.
     */
    public CallContext setBothCarrierCodes(String carrierCode) {
        setCalledCarrierCode(carrierCode);
        setCallingCarrierCode(carrierCode);

        return this;
    }

    public CallContext setCalledName(String name) {
        this.called.setName(name);
        return this;
    }

    public CallContext setCalledNetwork(String network) {
        this.called.setNetwork(network);
        return this;
    }

    public CallContext setCalledNumber(String number) {
        this.called.setNumber(number);
        return this;
    }

    public CallContext setCallingAccountCode(String accountCode) {
        this.calling.setAccountCode(accountCode);
        return this;
    }

    public CallContext setCallingCarrierCode(String carrierCode) {
        this.calling.setCarrierCode(carrierCode);
        return this;
    }

    public CallContext setCallingName(String name) {
        this.calling.setName(name);
        return this;
    }

    public CallContext setCallingNetwork(String network) {
        this.calling.setNetwork(network);
        return this;
    }

    public CallContext setCallingNumber(String number) {
        this.calling.setNumber(number);
        return this;
    }

    public CallContext setComplete(boolean value) {
        cdr.setComplete(value);
        return this;
    }

    public CallContext setDuration(int value) {
        cdr.setDuration(value);
        return this;
    }

    public CallContext setEffectiveCalledNumber(String effectiveCalledNumber) {
        this.called.setEffectiveNumber(effectiveCalledNumber);
        return this;
    }

    public CallContext setEndCause(String value) {
        cdr.setEndCause(value);
        return this;
    }

    public void setIcid(String icid) {
        cdr.setIcid(icid);
    }

    public void setMessage(String msg) {
        this.cdr.setMessage(msg);
    }

    public CallContext setNode(String value) {
        cdr.setNode(value);
        return this;
    }

    public boolean getPrivacy() {
        return (this.calling.getPresentation() == AddressPresentation.RESTRICTED);
    }

    public void setPrivacy(boolean privacy) {
        if (privacy) {
            this.calling.setPresentation(AddressPresentation.RESTRICTED);
        } else {
            this.calling.setPresentation(AddressPresentation.ALLOWED);
        }
    }

    public String getDialStatus() {
        return this.dialStatus;
    }

    public void setDialStatus(String dialStatus) {
        this.dialStatus = dialStatus;
    }

    public String getHangupCause() {
        return this.hangupCause;
    }

    public void setHangupCause(String hangupCause) {
        this.hangupCause = hangupCause;
    }
}
