package com.initsys.sigal.agent.agi;

import java.io.IOException;
import java.net.Socket;

import org.asteriskjava.fastagi.AgiServerThread;
import org.asteriskjava.fastagi.DefaultAgiServer;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

public class DefaultAgiServerTest {

	private DefaultAgiServer server;
	
	private AgiServerThread thread;

	@Test
	public void testStillFunctionningAfterCapacity()
			throws IllegalStateException, IOException, InterruptedException {
		Thread.sleep(1000);
		for (int i = 0; i < 5; i++) {
			final int j = i;
			System.err.println("Running thread " + j);
			new Socket("127.0.0.1", 32348);
			Thread.sleep(200);
			
		}
		Thread.sleep(2000);
	}

	@Before
	public void setUp() throws IOException {
		this.server = new DefaultAgiServer();
		this.server.setPort(32348);
		this.server.setPoolSize(1);
		this.server.setMaximumPoolSize(3);
		this.thread = new AgiServerThread(this.server);
		this.thread.startup();
	}

	@After
	public void tearDown() {
		this.server.shutdown();
	}
}
