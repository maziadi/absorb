package com.initsys.sigal.service.as.registry;

import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class CallRegistryImpl implements CallRegistry {

    /** logger */
    private static final Logger log = LoggerFactory.getLogger(CallRegistryImpl.class);

    public Map<String, CallRegistryCdr> inboundCalls;

    public Map<String, CallRegistryCdr> outboundCalls;

    public CallRegistryImpl() {
        this.inboundCalls = Collections
                .synchronizedMap(new HashMap<String, CallRegistryCdr>());
        this.outboundCalls = Collections
                .synchronizedMap(new HashMap<String, CallRegistryCdr>());
    }

    public void addCall(CallRegistryCdr cdr) {
        checkCdr(cdr);
        if (log.isDebugEnabled()) {
            log.debug("Adding " + cdr);
        }
        getMap(cdr).put(cdr.getIcid(), cdr);
    }

    private Map<String, CallRegistryCdr> getMap(CallRegistryCdr cdr) {
        return cdr.getInbound() ? this.inboundCalls : this.outboundCalls;
    }

    private void checkCdr(CallRegistryCdr cdr) {
        if (StringUtils.isBlank(cdr.getIcid())) {
            throw new IllegalArgumentException(
                    "CallRegistryCdr.icid cannot be blank");
        }
        if (cdr.getInbound() == null) {
            throw new NullPointerException(
                    "CallRegistryCdr.inbound cannot be null");
        }
    }

    public boolean hasCall(String icid) {
        return this.inboundCalls.containsKey(icid)
                || this.outboundCalls.containsKey(icid);
    }

    public boolean removeCall(CallRegistryCdr cdr) {
        checkCdr(cdr);
        if (log.isDebugEnabled()) {
            log.debug("Removing " + cdr);
        }
        return getMap(cdr).remove(cdr.getIcid()) != null;
    }

    /**
     * Counts inbound or outbound legs for a VNO (legs with the same ICID are
     * counted only once).
     */
    public int getCountByVno(String vnoName) {
        if (vnoName == null) {
            return 0;
        }
        int count = 0;
        Set<String> counted = new HashSet<String>();
        synchronized(this.inboundCalls) {
            for (Map.Entry<String, CallRegistryCdr> entry : this.inboundCalls
                    .entrySet()) {
                if (vnoName.equals(entry.getValue().getVnoName())) {
                    counted.add(entry.getValue().getIcid());
                    count++;
                }
            }
        }

        synchronized(this.outboundCalls) {
            for (Map.Entry<String, CallRegistryCdr> entry : this.outboundCalls
                    .entrySet()) {
                if (vnoName.equals(entry.getValue().getVnoName())
                        && !counted.contains(entry.getValue().getIcid())) {
                    count++;
                }
            }
        }

        return count;
    }

    /**
     * Number of calls by account (either inbound or outbound)
     */
    public int getCountByAccount(String accountCode) {
        if (accountCode == null) {
            return 0;
        }
        int count = 0;

        synchronized(this.inboundCalls) {
            for (Map.Entry<String, CallRegistryCdr> entry : this.inboundCalls
                    .entrySet()) {
                if (accountCode.equals(entry.getValue().getAccountCode())) {
                    count++;
                }
            }
        }

        synchronized(this.outboundCalls) {
            for (Map.Entry<String, CallRegistryCdr> entry : this.outboundCalls
                    .entrySet()) {
                if (accountCode.equals(entry.getValue().getAccountCode())) {
                    count++;
                }
            }
        }

        return count;
    }

    public int getInboundCountByAccount(String accountCode) {
        if (accountCode == null) {
            return 0;
        }
        int count = 0;

        synchronized(this.inboundCalls) {
            for (Map.Entry<String, CallRegistryCdr> entry : this.inboundCalls
                    .entrySet()) {
                if (accountCode.equals(entry.getValue().getAccountCode())
                        && entry.getValue().getInbound()) {
                    count++;
                }
            }
        }

        return count;
    }

    public int getOutboundCountByAccount(String accountCode) {
        if (accountCode == null) {
            return 0;
        }
        int count = 0;

        synchronized(this.outboundCalls) {
            for (Map.Entry<String, CallRegistryCdr> entry : this.outboundCalls
                    .entrySet()) {
                if (accountCode.equals(entry.getValue().getAccountCode())
                        && !entry.getValue().getInbound()) {
                    count++;
                }
            }
        }

        return count;
    }

    public void periodicCleanup(long maxCallDuration) {
        Date currentDate = new Date();

        cleanupCalls(maxCallDuration, currentDate, this.inboundCalls);
        cleanupCalls(maxCallDuration, currentDate, this.outboundCalls);
    }

    private void cleanupCalls(long maxCallDuration, Date currentDate, Map<String, CallRegistryCdr> calls) {
        for (Iterator<Map.Entry<String, CallRegistryCdr>> iterator = calls.entrySet().iterator(); iterator.hasNext();) {
            if (isTooLong(maxCallDuration, currentDate, iterator.next())) {
                iterator.remove();
            }
        }
    }

    /**
     * Prunes the call if it's beginDate is older than now minus
     * maxCallDuration.
     * 
     * @param maxCallDuration
     *            Max call duration in seconds.
     * @param currentDate
     *            Current date.
     * @param cdr
     *            CDR of the call to check and prune if too old.
     */
    private boolean isTooLong(long maxCallDuration, Date currentDate,
            Map.Entry<String, CallRegistryCdr> entry) {
        CallRegistryCdr cdr = entry.getValue();
        long diff = currentDate.getTime() - cdr.getBeginDate().getTime();

        maxCallDuration = maxCallDuration * 1000;
        if (diff < 0) {
            log.warn("Negative duration on " + cdr);
            diff = -diff;
        }
        if (diff > maxCallDuration) {
            log.warn("Call duration was too long, pruning " + cdr);
            return true;
        }
        return false;
    }
}
