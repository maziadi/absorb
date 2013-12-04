package com.initsys.sigal.agent;

import java.util.Iterator;

import org.apache.commons.collections.Buffer;
import org.apache.commons.collections.BufferUtils;
import org.apache.commons.collections.buffer.CircularFifoBuffer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jmx.export.annotation.ManagedAttribute;
import org.springframework.jmx.export.annotation.ManagedResource;

@ManagedResource
public class AgentStatisticsImpl implements AgentStatistics {

    /** logger */
    private static final Logger log = LoggerFactory.getLogger(AgentStatisticsImpl.class);

    /** Number of samples to hold in the buffer for statistics */
    static final int MAX_SAMPLES = 100;

    private String type = "";

    private transient long callCount = 0l;

    private transient long establishedCallCount = 0l;

    private transient long unallocatedCauseCount = 0l;

    private transient long busyCauseCount = 0l;

    private transient long congestionCauseCount = 0l;

    private transient long exceptionCount = 0l;

    private Buffer durations = BufferUtils
            .synchronizedBuffer(new CircularFifoBuffer(MAX_SAMPLES));

    private Buffer billableDurations = BufferUtils
            .synchronizedBuffer(new CircularFifoBuffer(MAX_SAMPLES));

    private Buffer treatmentDurations = BufferUtils
            .synchronizedBuffer(new CircularFifoBuffer(MAX_SAMPLES));

    private Buffer inviteLatencies = BufferUtils
            .synchronizedBuffer(new CircularFifoBuffer(MAX_SAMPLES));

    /* (non-Javadoc)
     * @see com.initsys.sigal.agent.AgentStatistics#addBillableDuration(java.lang.Integer)
     */
    @SuppressWarnings("unchecked")
    public void addBillableDuration(Integer duration) {
        this.billableDurations.add(duration);
    }

    /* (non-Javadoc)
     * @see com.initsys.sigal.agent.AgentStatistics#addDuration(java.lang.Integer)
     */
    @SuppressWarnings("unchecked")
    public void addDuration(Integer duration) {
        this.durations.add(duration);
    }

    /* (non-Javadoc)
     * @see com.initsys.sigal.agent.AgentStatistics#addTreatmentDuration(java.lang.Integer)
     */
    @SuppressWarnings("unchecked")
    public void addTreatmentDuration(Integer duration) {
        this.treatmentDurations.add(duration);
    }

    /* (non-Javadoc)
     * @see com.initsys.sigal.agent.AgentStatistics#addInviteLatency(java.lang.Integer)
     */
    @SuppressWarnings("unchecked")
    public void addInviteLatency(Integer latency) {
        this.inviteLatencies.add(latency);
    }

    @ManagedAttribute
    public Long getBusyCauseCount() {
        return busyCauseCount;
    }

    @ManagedAttribute
    public Long getCallCount() {
        return callCount;
    }

    @ManagedAttribute
    public Long getCongestionCauseCount() {
        return congestionCauseCount;
    }

    @ManagedAttribute
    public Long getEstablishedCallCount() {
        return establishedCallCount;
    }

    @ManagedAttribute
    public Long getExceptionCount() {
        return exceptionCount;
    }

    @ManagedAttribute
    public Double getMeanBillableDuration() {
        return getMeanFromBuffer(this.billableDurations);
    }

    @ManagedAttribute
    public Double getMeanDuration() {
        return getMeanFromBuffer(this.durations);
    }

    @ManagedAttribute
    @SuppressWarnings("unchecked")
    private Double getMeanFromBuffer(Buffer buffer) {
        Double sum = 0.0;
        int size = buffer.size();
        if (size == 0) {
            return 0.0;
        }
        for (Iterator ite = buffer.iterator(); ite.hasNext();) {
            sum += (Integer) ite.next();
        }
        return sum / size;
    }

    @ManagedAttribute
    public Double getMeanTreatmentDuration() {
        return getMeanFromBuffer(this.treatmentDurations);
    }

    @ManagedAttribute
    public Double getMeanInviteLatency() {
        return getMeanFromBuffer(this.inviteLatencies);
    }

    @ManagedAttribute
    public String getType() {
        return type;
    }

    @ManagedAttribute
    public Long getUnallocatedCauseCount() {
        return unallocatedCauseCount;
    }

    /**
     * @see com.initsys.sigal.agent.AgentStatistics#incrementBusyCauseCount()
     */
    public void incrementBusyCauseCount() {
        this.busyCauseCount += 1;
    }

    /**
     * @see com.initsys.sigal.agent.AgentStatistics#incrementExceptionCount()
     */
    public void incrementExceptionCount() {
        this.exceptionCount += 1;
    }

    /**
     * @see com.initsys.sigal.agent.AgentStatistics#incrementCallCount()
     */
    public void incrementCallCount() {
        this.callCount += 1;
    }

    /**
     * @see com.initsys.sigal.agent.AgentStatistics#incrementCongestionCauseCount()
     */
    public void incrementCongestionCauseCount() {
        this.congestionCauseCount += 1;
    }

    /**
     * @see com.initsys.sigal.agent.AgentStatistics#incrementEstablishedCallCount()
     */
    public void incrementEstablishedCallCount() {
        this.establishedCallCount += 1;
    }

    /**
     * @see com.initsys.sigal.agent.AgentStatistics#incrementUnallocatedCauseCount()
     */
    public void incrementUnallocatedCauseCount() {
        this.unallocatedCauseCount += 1;
    }

    public void log() {
        log.info(toString());
    }

    public void setType(String type) {
        this.type = type;
    }

    @Override
    public String toString() {
        return String
                .format(
                        "AGENT STATS[%s]: #call: %d, #established: %d, #unallocated: %d, #busy: %d, #congestion: %d, "
                                + "#exception: %d, ~duration: %2.2f, ~billableDuration: %2.2f, ~treatmentDuration: %2.2f",
                        getType(), getCallCount(), getEstablishedCallCount(),
                        getUnallocatedCauseCount(), getBusyCauseCount(),
                        getCongestionCauseCount(), getExceptionCount(),
                        getMeanDuration(), getMeanBillableDuration(),
                        getMeanTreatmentDuration());
    }
}
