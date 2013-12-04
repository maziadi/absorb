package com.initsys.sigal.service.as.registry;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.util.Date;

import org.junit.Before;
import org.junit.Test;

public class CallRegistryTest {

    private static final String TEST_ICID1 = "icid0001";
    private static final String TEST_ICID2 = "icid0002";
    private static final String TEST_ICID3 = "icid0003";
    private static final String TEST_ICID4 = "icid0004";
    private static final String TEST_VNO1 = "vno1";
    private static final String TEST_VNO2 = "vno2";
    private static final String TEST_ACCOUNT1 = "acc001";
    private static final String TEST_ACCOUNT2 = "acc002";
    private static final String TEST_ACCOUNT3 = "acc003";

    private CallRegistryImpl registry;

    private void assertAccountCount(long count, String account) {
        assertEquals(count, getRegistry().getCountByAccount(account));
    }

    private void assertVnoCount(long count, String vno) {
        assertEquals(count, getRegistry().getCountByVno(vno));
    }

    private CallRegistryCdr createSimpleCdr() {
        CallRegistryCdr cdr = new CallRegistryCdr(TEST_ICID1, TEST_VNO1, null,
                true, null);
        return cdr;
    }

    public CallRegistryImpl getRegistry() {
        return registry;
    }

    @Test
    public void icidIsNull() {
        CallRegistryCdr cdr = new CallRegistryCdr();

        try {
            getRegistry().addCall(cdr);
            fail("Should have thrown an IllegalArgumentException");
        } catch (IllegalArgumentException e) {
            // ok
        }

    }

    public void setRegistry(CallRegistryImpl registry) {
        this.registry = registry;
    }

    @Before
    public void setUp() {
        setRegistry(new CallRegistryImpl());
    }

    @Test
    public void addCall() {
        CallRegistryCdr cdr = createSimpleCdr();

        getRegistry().addCall(cdr);
        assertTrue(getRegistry().hasCall(cdr.getIcid()));

    }

    @Test
    public void testInboundAndOutbound() {
        assertAccountCount(0, null);
        assertAccountCount(0, TEST_ACCOUNT1);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, TEST_ACCOUNT1, true,
                        null));
        assertVnoCount(1, TEST_VNO1);
        assertAccountCount(1, TEST_ACCOUNT1);
        assertInboundAccountCount(1, TEST_ACCOUNT1);
        assertOutboundAccountCount(0, TEST_ACCOUNT1);
        assertAccountCount(0, TEST_ACCOUNT2);
        assertInboundAccountCount(0, TEST_ACCOUNT2);
        assertOutboundAccountCount(0, TEST_ACCOUNT2);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, TEST_ACCOUNT2,
                        false, null));
        assertVnoCount(1, TEST_VNO1);
        assertAccountCount(1, TEST_ACCOUNT1);
        assertInboundAccountCount(1, TEST_ACCOUNT1);
        assertOutboundAccountCount(0, TEST_ACCOUNT1);
        assertAccountCount(1, TEST_ACCOUNT2);
        assertInboundAccountCount(0, TEST_ACCOUNT2);
        assertOutboundAccountCount(1, TEST_ACCOUNT2);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, TEST_ACCOUNT2,
                        false, null));
        assertVnoCount(1, TEST_VNO1);
        assertAccountCount(1, TEST_ACCOUNT1);
        assertInboundAccountCount(1, TEST_ACCOUNT1);
        assertOutboundAccountCount(0, TEST_ACCOUNT1);
        assertAccountCount(0, TEST_ACCOUNT2);
        assertInboundAccountCount(0, TEST_ACCOUNT2);
        assertOutboundAccountCount(0, TEST_ACCOUNT2);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, TEST_ACCOUNT1, true,
                        null));
        assertVnoCount(0, TEST_VNO1);
        assertAccountCount(0, TEST_ACCOUNT1);
        assertInboundAccountCount(0, TEST_ACCOUNT1);
        assertOutboundAccountCount(0, TEST_ACCOUNT1);
        assertAccountCount(0, TEST_ACCOUNT2);
        assertInboundAccountCount(0, TEST_ACCOUNT2);
        assertOutboundAccountCount(0, TEST_ACCOUNT2);

    }

    @Test
    public void countByAccount() {
        assertAccountCount(0, null);
        assertAccountCount(0, TEST_ACCOUNT1);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, TEST_ACCOUNT1, true,
                        null));
        assertAccountCount(1, TEST_ACCOUNT1);
        assertAccountCount(0, TEST_ACCOUNT2);
        assertAccountCount(0, TEST_ACCOUNT3);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID2, TEST_VNO1, TEST_ACCOUNT2, true,
                        null));
        assertAccountCount(1, TEST_ACCOUNT1);
        assertAccountCount(1, TEST_ACCOUNT2);
        assertAccountCount(0, TEST_ACCOUNT3);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID3, TEST_VNO2, TEST_ACCOUNT3,
                        false, null));
        assertAccountCount(1, TEST_ACCOUNT1);
        assertAccountCount(1, TEST_ACCOUNT2);
        assertAccountCount(1, TEST_ACCOUNT3);
        assertAccountCount(0, null);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID4, TEST_VNO1, TEST_ACCOUNT1,
                        false, null));
        assertAccountCount(2, TEST_ACCOUNT1);
        assertAccountCount(1, TEST_ACCOUNT2);
        assertAccountCount(1, TEST_ACCOUNT3);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID2, null, null, true, null));
        assertAccountCount(2, TEST_ACCOUNT1);
        assertAccountCount(0, TEST_ACCOUNT2);
        assertAccountCount(1, TEST_ACCOUNT3);
        assertAccountCount(0, null);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID3, null, null, false, null));
        assertAccountCount(2, TEST_ACCOUNT1);
        assertAccountCount(0, TEST_ACCOUNT2);
        assertAccountCount(0, TEST_ACCOUNT3);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID1, null, null, true, null));
        assertAccountCount(1, TEST_ACCOUNT1);
        assertAccountCount(0, TEST_ACCOUNT2);
        assertAccountCount(0, TEST_ACCOUNT3);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID4, null, null, false, null));
        assertAccountCount(0, TEST_ACCOUNT1);
        assertAccountCount(0, TEST_ACCOUNT2);
        assertAccountCount(0, TEST_ACCOUNT3);

    }

    @Test
    public void countOutgoingByAccount() {
        assertOutboundAccountCount(0, null);
        assertOutboundAccountCount(0, TEST_ACCOUNT1);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, TEST_ACCOUNT1,
                        false, null));
        assertOutboundAccountCount(1, TEST_ACCOUNT1);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID2, TEST_VNO1, TEST_ACCOUNT1, true,
                        null));
        assertOutboundAccountCount(1, TEST_ACCOUNT1);
    }

    private void assertOutboundAccountCount(int count, String accountCode) {
        assertEquals(count, getRegistry()
                .getOutboundCountByAccount(accountCode));
    }

    @Test
    public void countInboundByAccount() {
        assertInboundAccountCount(0, null);
        assertInboundAccountCount(0, TEST_ACCOUNT1);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, TEST_ACCOUNT1, true,
                        null));
        assertInboundAccountCount(1, TEST_ACCOUNT1);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID2, TEST_VNO1, TEST_ACCOUNT1,
                        false, null));
        assertInboundAccountCount(1, TEST_ACCOUNT1);
    }

    private void assertInboundAccountCount(int count, String accountCode) {
        assertEquals(count, getRegistry().getInboundCountByAccount(accountCode));
    }

    @Test
    public void countByVno() {
        assertVnoCount(0, null);
        assertVnoCount(0, TEST_VNO1);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, null, true, null));
        assertVnoCount(1, TEST_VNO1);
        assertVnoCount(0, TEST_VNO2);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID2, TEST_VNO1, null, true, null));
        assertVnoCount(2, TEST_VNO1);
        assertVnoCount(0, TEST_VNO2);

        getRegistry().addCall(
                new CallRegistryCdr(TEST_ICID3, TEST_VNO2, null, false, null));
        assertVnoCount(2, TEST_VNO1);
        assertVnoCount(1, TEST_VNO2);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID2, TEST_VNO1, null, true, null));
        assertVnoCount(1, TEST_VNO1);
        assertVnoCount(1, TEST_VNO2);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID3, TEST_VNO1, null, false, null));
        assertVnoCount(1, TEST_VNO1);
        assertVnoCount(0, TEST_VNO2);
        assertVnoCount(0, null);

        getRegistry().removeCall(
                new CallRegistryCdr(TEST_ICID1, TEST_VNO1, null, true, null));
        assertVnoCount(0, TEST_VNO1);
        assertVnoCount(0, TEST_VNO2);
    }

    @Test
    public void testRemoveCall() {
        CallRegistryCdr cdr = createSimpleCdr();

        getRegistry().addCall(cdr);
        assertFalse(getRegistry().removeCall(
                new CallRegistryCdr("xyz", TEST_VNO1, null, true, null)));
        assertTrue(getRegistry().removeCall(cdr));
        assertFalse(getRegistry().removeCall(
                new CallRegistryCdr("xyz", TEST_VNO1, null, true, null)));
        assertFalse(getRegistry().removeCall(cdr));
    }

    @Test
    public void testRemoveCallNotSameDirection() {
        CallRegistryCdr cdr = createSimpleCdr();
        CallRegistryCdr otherDirectionCdr = createSimpleCdr();
        otherDirectionCdr.setInbound(false);

        getRegistry().addCall(cdr);
        assertFalse(getRegistry().removeCall(otherDirectionCdr));
        assertTrue(getRegistry().removeCall(cdr));
        assertFalse(getRegistry().removeCall(cdr));
    }

    @Test
    public void testCleanup() {
        Date currentDate = new Date();

        CallRegistryCdr cdr1 = new CallRegistryCdr(TEST_ICID1, TEST_VNO1, null,
                false, new Date(currentDate.getTime() - 1100000));
        CallRegistryCdr cdr2 = new CallRegistryCdr(TEST_ICID2, TEST_VNO1, null,
                true, new Date(currentDate.getTime() - 900000));
        // test when duration is negative
        CallRegistryCdr cdr3 = new CallRegistryCdr(TEST_ICID3, TEST_VNO1, null,
                true, new Date(currentDate.getTime() + 1100000));

        getRegistry().addCall(cdr1);
        getRegistry().addCall(cdr2);
        getRegistry().addCall(cdr3);

        assertEquals(3, getRegistry().getCountByVno(TEST_VNO1));
        getRegistry().periodicCleanup(1000);
        assertEquals(1, getRegistry().getCountByVno(TEST_VNO1));
    }
}
