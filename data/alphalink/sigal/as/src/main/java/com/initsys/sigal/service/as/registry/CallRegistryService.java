package com.initsys.sigal.service.as.registry;

import com.initsys.sigal.protocol.Sigal.Cdr;

public interface CallRegistryService {

    /**
     * 
     * Handles CDR messages and updates the service.
     * 
     * @param cdr
     */
    public void onMessage(Cdr cdr);

    /**
     * Cleans up the registry. Should be called periodically to maintain the
     * registry in a clean state.
     */
    public void periodicCleanup();

}
