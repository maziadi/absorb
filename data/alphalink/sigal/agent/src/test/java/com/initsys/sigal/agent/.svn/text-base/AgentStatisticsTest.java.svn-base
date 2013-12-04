package com.initsys.sigal.agent;

import static junit.framework.Assert.assertEquals;

import org.junit.Before;
import org.junit.Test;

public class AgentStatisticsTest {

    private AgentStatisticsImpl statistics;

    @Before
    public void setUp() {
        this.statistics = new AgentStatisticsImpl();
        this.statistics.setType("TEST");
    }

    @Test
    public void testMeans() {
        this.statistics.addDuration(100);
        assertMeans(100, 0, 0);
        this.statistics.addBillableDuration(200);
        assertMeans(100, 200, 0);
        this.statistics.addTreatmentDuration(300);
        assertMeans(100, 200, 300);
        this.statistics.addDuration(100);
        assertMeans(100, 200, 300);
        this.statistics.addDuration(400);
        assertMeans(200, 200, 300);
        this.statistics.addDuration(200);
        assertMeans(200, 200, 300);
    }

    @Test
      public void testCircularBuffer() {
        for(int i = 0; i < AgentStatisticsImpl.MAX_SAMPLES; i++) {
          this.statistics.addDuration(100);
        }
        this.statistics.addDuration(100); // should work
      }

    private void assertMeans(double meanDuration, double meanBillableDuration,
            double meanQueryDuration) {
        assertEquals(meanDuration, this.statistics.getMeanDuration());
        assertEquals(meanBillableDuration, this.statistics
                .getMeanBillableDuration());
        assertEquals(meanQueryDuration, this.statistics
                .getMeanTreatmentDuration());
        System.out.println(this.statistics);
    }

}
