package com.initsys.sigal.service.as;

import org.apache.commons.lang.time.StopWatch;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.protobuf.Message;

public abstract class AbstractSigalAsService {

    /** logger */
    private static final Logger log = LoggerFactory
            .getLogger(AbstractSigalAsService.class);

    public abstract Message handleQuery(Message query);

    public Message onMessage(Message query) {
        StopWatch watch = new StopWatch();

        watch.start();
        Message response = null;
        try {
            return handleQuery(query);
        } finally {
            watch.stop();
            if (log.isDebugEnabled()) {
                log.debug(String.format("Queried in %3dms: \n  %s\n  %s", watch
                        .getTime(), query.toString().replaceAll("\n", "\n  "),
                        response == null ? "<null>" : response.toString()
                                .replaceAll("\n", "\n  ")));
            }
        }
    }

    public void sleep(long duration) {
      try {
        log.info("Sleeping for "+ String.valueOf(duration) + " ms");
        Thread.sleep(duration);
      } catch (InterruptedException e) {
        log.error("InterruptedException occured ");
      } catch (IllegalMonitorStateException e) {
        log.error("IllegalMonitorStateException occured ");
      }
    }
}
