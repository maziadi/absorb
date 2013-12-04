package com.initsys.sigal.service.as.registry;

import org.easymock.EasyMock;
import static org.easymock.EasyMock.*;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.easymock.IMocksControl;
import org.junit.Before;
import org.junit.Test;

import com.initsys.sigal.protocol.Sigal.CallAddress;
import com.initsys.sigal.protocol.Sigal.Cdr;
import com.initsys.sigal.vno.VnoConstants;

public class CallRegistryServiceTest {

    private static final String TEST_CALLED_ACCOUNT_CODE = "acc_called";

    private static final String TEST_VNO_NAME = "abc";

    private static final String TEST_CALLING_ACCOUNT_CODE = "acc_calling";

    private static final String TEST_ICID = "0000-1111";

    /** <b>Seconds</b> since EPOCH */
    private static final long TEST_DATE = 1234567890;
    
    private CallRegistryServiceImpl service;

    private IMocksControl mockCtrl;

    @Before
    public void setUp() {
        this.mockCtrl = EasyMock.createStrictControl();
        this.service = new CallRegistryServiceImpl();
        this.service.setCallRegistry(mockCtrl.createMock(CallRegistry.class));
    }

    @Test
    public void addCall() {
        Cdr.Builder cdr = createCdr(true);
        cdr.setComplete(false);
        CallRegistryCdr crCdr = createCrCdr(true);
        this.service.getCallRegistry().addCall(crCdr);

        executeAndVerify(cdr.build());
    }

    @Test
    public void removeCall() {
        Cdr.Builder cdr = createCdr(true);
        CallRegistryCdr crCdr = createCrCdr(true);

        expect(this.service.getCallRegistry().removeCall(crCdr))
                .andReturn(true);

        executeAndVerify(cdr.build());
    }

    private Cdr.Builder createCdr(boolean inbound) {
        CallAddress calling = CallAddress.newBuilder().setVersion(1)
                .setNetwork(
                        inbound ? VnoConstants.EXTERNAL_NETWORK
                                : VnoConstants.INTERNAL_NETWORK)
                .setCarrierCode(TEST_VNO_NAME + ".1").setAccountCode(TEST_CALLING_ACCOUNT_CODE).setName(
                        "Toto").setNumber("33123456789").build();

        CallAddress called = CallAddress.newBuilder().setVersion(1).setNetwork(
                inbound ? VnoConstants.INTERNAL_NETWORK
                        : VnoConstants.EXTERNAL_NETWORK)
                .setCarrierCode(TEST_VNO_NAME + ".1").setAccountCode(TEST_CALLED_ACCOUNT_CODE).setName(
                        "Titi").setNumber("33000000000").build();

        Cdr.Builder cdr = Cdr.newBuilder().setVersion(1).setComplete(true)
                .setCalling(calling).setCalled(called).setIcid(TEST_ICID).setBeginDate(TEST_DATE);
        return cdr;
    }

    private CallRegistryCdr createCrCdr(boolean inbound) {
        CallRegistryCdr crCdr = new CallRegistryCdr();
        crCdr.setAccountCode(inbound ? TEST_CALLING_ACCOUNT_CODE : TEST_CALLED_ACCOUNT_CODE);
        crCdr.setIcid(TEST_ICID);
        crCdr.setVnoName(TEST_VNO_NAME);
        crCdr.setInbound(inbound);
        return crCdr;
    }

    @Test
    public void testBuildCdr() {
        Cdr inboundCdr = createCdr(true).build();
        Cdr outboundCdr = createCdr(false).build();

        CallRegistryCdr inboundCrCdr = this.service
                .buildCrCdrFromMessage(inboundCdr);
        CallRegistryCdr outboundCrCdr = this.service
                .buildCrCdrFromMessage(outboundCdr);

        assertEquals(TEST_DATE * 1000, inboundCrCdr.getBeginDate().getTime());
        assertEquals(TEST_ICID, inboundCrCdr.getIcid());
        assertEquals(TEST_VNO_NAME, inboundCrCdr.getVnoName());
        assertEquals(TEST_CALLING_ACCOUNT_CODE, inboundCrCdr.getAccountCode());
        assertTrue(inboundCrCdr.getInbound());

        assertEquals(TEST_DATE * 1000, outboundCrCdr.getBeginDate().getTime());
        assertEquals(TEST_ICID, outboundCrCdr.getIcid());
        assertEquals(TEST_VNO_NAME, outboundCrCdr.getVnoName());
        assertEquals(TEST_CALLED_ACCOUNT_CODE, outboundCrCdr.getAccountCode());
        assertFalse(outboundCrCdr.getInbound());
    }

    @Test
    public void removeCallNotPresent() {
        Cdr.Builder cdr = createCdr(false);
        CallRegistryCdr crCdr = createCrCdr(false);

        expect(this.service.getCallRegistry().removeCall(crCdr)).andReturn(
                false);

        executeAndVerify(cdr.build());
    }

    private void executeAndVerify(Cdr cdr) {
        this.mockCtrl.replay();
        this.service.onMessage(cdr);
        this.mockCtrl.verify();
    }
}
