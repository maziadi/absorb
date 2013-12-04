package com.mycompany.app;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import static org.junit.Assert.*;


/**
 * Unit test for simple App.
 */
public class AppTest {
  protected App op;

  @Before
  public void setUp() {
    op = new App();
  }

  @After
  public void tearDown() {
  }

  @Test
  public void testCalculer() throws Exception {
    assertEquals(new Long(4),
        op.calculer(new Long(1), new Long(3)));
  }

  @Test
  public void testLireSymbole() throws Exception {
    assertEquals((Character)'+', op.lireSymbole());
  }
  /* /** */
  /*  * Create the test case */
  /*  * */
  /*  * @param testName name of the test case */
  /*  */ */
  /* public AppTest( String testName ) */
  /* { */
  /*     super( testName ); */
  /* } */

  /* /** */
  /*  * @return the suite of tests being tested */
  /*  */ */
  /* public static Test suite() */
  /* { */
  /*     return new TestSuite( AppTest.class ); */
  /* } */

  /* /** */
  /*  * Rigourous Test :-) */
  /*  */ */
  /* public void testApp() */
  /* { */
  /*     assertTrue( true ); */
  /* } */
}
