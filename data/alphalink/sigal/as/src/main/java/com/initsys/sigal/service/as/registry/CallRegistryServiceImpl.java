package com.initsys.sigal.service.as.registry;

import java.util.Date;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.initsys.sigal.protocol.Sigal.Cdr;
import com.initsys.sigal.service.as.dao.ExdbDao;
import com.initsys.sigal.service.as.dao.LidbDao;
import com.initsys.sigal.vno.VnoConstants;
import com.initsys.sigal.vno.VnoUtils;

public class CallRegistryServiceImpl implements CallRegistryService {

    /** logger */
    private static final Logger log = LoggerFactory
            .getLogger(CallRegistryServiceImpl.class);

    private CallRegistry callRegistry;

    private String nodeName;

    private long maxCallDuration;

    public long getMaxCallDuration() {
        return maxCallDuration;
    }

    public void setMaxCallDuration(long maxCallDuration) {
        this.maxCallDuration = maxCallDuration;
    }

    public String getNodeName() {
        return nodeName;
    }

    public void setNodeName(String nodeName) {
        this.nodeName = nodeName;
    }

    private LidbDao lidbDao;

    public LidbDao getLidbDao() {
        return lidbDao;
    }

    public void setLidbDao(LidbDao lidbDao) {
        this.lidbDao = lidbDao;
    }

    public ExdbDao getExdbDao() {
        return exdbDao;
    }

    public void setExdbDao(ExdbDao exdbDao) {
        this.exdbDao = exdbDao;
    }

    private ExdbDao exdbDao;

    public CallRegistry getCallRegistry() {
        return callRegistry;
    }

    public void setCallRegistry(CallRegistry callRegistry) {
        this.callRegistry = callRegistry;
    }

    public void onMessage(Cdr cdr) {
        if (log.isDebugEnabled()) {
            log.debug("Handling CDR: "
                    + cdr.toString().replaceAll(" *[\n\r]+ *", " "));
        }

        if (cdr.getComplete()) {
            boolean present = getCallRegistry().removeCall(
                    buildCrCdrFromMessage(cdr));
            if (!present) {
                log.warn("Tried to remove call wich was not present: " + cdr);
            }
        } else {
            getCallRegistry().addCall(buildCrCdrFromMessage(cdr));
        }
    }

    CallRegistryCdr buildCrCdrFromMessage(Cdr cdr) {
        CallRegistryCdr crCdr = new CallRegistryCdr();

        crCdr.setIcid(cdr.getIcid());
        crCdr.setInbound(VnoConstants.EXTERNAL_NETWORK.equals(cdr.getCalling()
                .getNetwork()));
        if (crCdr.getInbound()) {
            crCdr.setAccountCode(cdr.getCalling().getAccountCode());
        } else {
            crCdr.setAccountCode(cdr.getCalled().getAccountCode());
        }
        crCdr
                .setVnoName(VnoUtils.getVnoName(cdr.getCalling()
                        .getCarrierCode()));
        crCdr.setBeginDate(new Date(cdr.getBeginDate() * 1000));
        return crCdr;
    }

    public void dumpState() {

    }

    public void periodicCleanup() {
        log.debug("Starting periodic cleanup");
        getCallRegistry().periodicCleanup(getMaxCallDuration());
        log.debug("Periodic cleanup finished.");
    }

}
