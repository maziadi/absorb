package com.initsys.sigal.agent.scenario;

import org.jbehave.scenario.JUnitScenario;
import org.jbehave.scenario.MostUsefulConfiguration;
import org.jbehave.scenario.PropertyBasedConfiguration;
import org.jbehave.scenario.parser.ClasspathScenarioDefiner;
import org.jbehave.scenario.parser.PatternScenarioParser;
import org.jbehave.scenario.parser.ScenarioDefiner;
import org.jbehave.scenario.parser.UnderscoredCamelCaseResolver;

import com.initsys.sigal.agent.scenario.steps.CallSteps;

public abstract class AbstractScenario extends JUnitScenario {
	public AbstractScenario() {
		this(Thread.currentThread().getContextClassLoader());
	}

	public AbstractScenario(final ClassLoader classLoader) {
		super(new MostUsefulConfiguration() {
			public ScenarioDefiner forDefiningScenarios() {
				return new ClasspathScenarioDefiner(
						new UnderscoredCamelCaseResolver(".scenario"),
						new PatternScenarioParser(
								new PropertyBasedConfiguration()), classLoader);
			}
		}, new CallSteps());
	}
}
