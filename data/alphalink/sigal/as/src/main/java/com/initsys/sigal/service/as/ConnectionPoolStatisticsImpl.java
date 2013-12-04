package com.initsys.sigal.service.as;

import org.apache.commons.dbcp.BasicDataSource;
import org.springframework.jmx.export.annotation.ManagedAttribute;
import org.springframework.jmx.export.annotation.ManagedResource;

@ManagedResource
public class ConnectionPoolStatisticsImpl implements ConnectionPoolStatistics {
  private BasicDataSource dataSource;

  /**
   * Constructor, initialised with the BasicDataSource to be managed.
   * @param dataSource The datasource to manage
   */
  public ConnectionPoolStatisticsImpl(BasicDataSource source) {
    this.dataSource = source;
  }

  /**
   * The current number of active connections allocated from the managed datasource.
   * @return  The current number of active connections
   */
  @ManagedAttribute
  public int getNumActive() {
    return dataSource.getNumActive();
  }

  /**
   * The current number of idle connections waiting to be allocated from the managed datasource.
   * @return  The current number of active connections
   */
  @ManagedAttribute
  public int getNumIdle() {
    return dataSource.getNumIdle();
  }

  /**
   * <p>Returns the maximum number of active connections that can be allocated at the same time.
   * </p>
   * <p>A negative number means that there is no limit.</p>
   *
   * @return the maximum number of active connections
   */
  @ManagedAttribute
  public int getMaxActive() {
    return dataSource.getMaxActive();
  }

  /**
   * Sets the maximum number of active connections that can be
   * allocated at the same time. Use a negative value for no limit.
   *
   * @param maxActive the new value for maxActive
   */
  public void setMaxActive(int maxActive) {
    dataSource.setMaxActive(maxActive);
  }

  /**
   * <p>Returns the maximum number of connections that can remain idle in the pool.</p>
   * <p>A negative value indicates that there is no limit</p>
   *
   * @return the maximum number of idle connections
   */
  public synchronized int getMaxIdle() {
    return dataSource.getMaxIdle();
  }

  /**
   * Sets the maximum number of connections that can remain idle in the pool.
   *
   * @param maxIdle the new value for maxIdle
   */
  public synchronized void setMaxIdle(int maxIdle) {
    dataSource.setMaxIdle(maxIdle);
  }

  /**
   * Returns the minimum number of idle connections in the pool.
   *
   * @return the minimum number of idle connections
   * @see org.apache.commons.pool.impl.GenericObjectPool#getMinIdle()
   */
  @ManagedAttribute
  public synchronized int getMinIdle() {
    return dataSource.getMinIdle();
  }

  /**
   * Sets the minimum number of idle connections in the pool.
   *
   * @param minIdle the new value for minIdle
   * @see org.apache.commons.pool.impl.GenericObjectPool#setMinIdle(int)
   */
  public synchronized void setMinIdle(int minIdle) {
    dataSource.setMinIdle(minIdle);
  }

  /**
   * <p>Returns the maximum number of milliseconds that the pool will wait
   * for a connection to be returned before throwing an exception.
   * </p>
   * <p>A value less than or equal to zero means the pool is set to wait indefinitely.</p>
   *
   * @return the maxWait property value
   */
  @ManagedAttribute
  public synchronized long getMaxWait() {
    return dataSource.getMaxWait();
  }

  /**
   * <p>Sets the maxWait property.</p>
   * <p>Use -1 to make the pool wait indefinitely.</p>
   *
   * @param maxWait the new value for maxWait
   * @see #getMaxWait()
   */
  public synchronized void setMaxWait(long maxWait) {
    dataSource.setMaxWait(maxWait);
  }
}
