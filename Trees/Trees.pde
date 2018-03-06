import heronarts.lx.*;
import heronarts.lx.audio.*;
import heronarts.lx.effect.*;
import heronarts.lx.midi.*;
import heronarts.lx.model.*;
import heronarts.lx.output.*;
import heronarts.lx.parameter.*;
import heronarts.lx.pattern.*;
import heronarts.lx.transform.*;
import heronarts.lx.transition.*;
import heronarts.lx.midi.*;
import heronarts.lx.modulator.*;

import heronarts.p3lx.*;
import heronarts.p3lx.ui.*;
import heronarts.p3lx.ui.component.*;
import heronarts.p3lx.ui.control.*;

import ddf.minim.*;
import processing.opengl.*;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;

final static float CHAIN = -12*Geometry.INCHES;
final static float BOLT = 22*Geometry.INCHES;

static List<TreeConfig> clusterConfig;

Model model;
P3LX lx;
ProcessingEngine engine;
LXDatagramOutput output;
BasicParameter outputBrightness;
LXDatagram[] datagrams;
UIChannelFaders uiFaders;
UIMultiDeck uiDeck;
BPMTool bpmTool;
MappingTool mappingTool;
LXAutomationRecorder[] automation;
BooleanParameter[] automationStop;
DiscreteParameter automationSlot;
LXListenableNormalizedParameter[] effectKnobParameters;
BooleanParameter[] previewChannels;

void setup() {
  size(1148, 720, OPENGL);
  frameRate(90); // this will get processing 2 to actually hit around 60
}

class ProcessingEngine extends Engine {

  ProcessingEngine(String projectPath) {
    super(projectPath);
  }

  LX createLX() {
    return new P3LX(Trees.this, model);
  }

  P3LX getLX() {
    return (P3LX)lx;
  }

  void postCreateLX() {
    super.postCreateLX();

    lx.addEffect(mappingTool = new MappingTool(lx, clusterConfig));

    Trees.this.clusterConfig = clusterConfig;
    Trees.this.model = model;
    Trees.this.lx = getLX();
    Trees.this.output = output;
    Trees.this.outputBrightness = outputBrightness;
    Trees.this.datagrams = datagrams;
    Trees.this.bpmTool = bpmTool;
    Trees.this.automation = automation;
    Trees.this.automationStop = automationStop; 
    Trees.this.automationSlot = automationSlot;
    Trees.this.effectKnobParameters = effectKnobParameters;
    Trees.this.previewChannels = previewChannels;

    uiDeck = Trees.this.uiDeck = new UIMultiDeck(Trees.this.lx.ui);

    configureUI();
  }

  void addPatterns(ArrayList<LXPattern> patterns) {
    super.addPatterns(patterns);
    if (Config.enableSoundSyphon) {
      try { patterns.add(new SyphonPattern(lx, Trees.this)); } catch (Throwable e) {}
    }
  }
}

/* configureUI */

void configureUI() {
  // UI initialization
  lx.ui.addLayer(new UI3dContext(lx.ui) {
      protected void beforeDraw(UI ui, PGraphics pg) {
        hint(ENABLE_DEPTH_TEST);
        pushMatrix();
        translate(0, 12*Geometry.FEET, 0);
      }
      protected void afterDraw(UI ui, PGraphics pg) {
        popMatrix();
        hint(DISABLE_DEPTH_TEST);
      }  
    }
    .setRadius(90*Geometry.FEET)
    .setCenter(model.cx, model.cy, model.cz)
    .setTheta(30*Utils.PI/180)
    .setPhi(10*Utils.PI/180)
    .addComponent(new UITrees())
  );
  if (Config.enableOutputBigtree) {
    lx.ui.addLayer(new UIOutput(lx.ui, 4, 4));
  }
  lx.ui.addLayer(new UIMapping(lx.ui));
  lx.ui.addLayer(uiFaders = new UIChannelFaders(lx.ui));
  lx.ui.addLayer(new UIEffects(lx.ui, effectKnobParameters));
  lx.ui.addLayer(uiDeck);
  lx.ui.addLayer(new UILoopRecorder(lx.ui));
  lx.ui.addLayer(new UIMasterBpm(lx.ui, Trees.this.width-144, 4, bpmTool));
}

void draw() {
  background(#222222);
  
  if (engine == null) {
    engine = new ProcessingEngine(sketchPath());
    engine.start();
  }
}

TreesTransition getFaderTransition(LXChannel channel) {
  return (TreesTransition) channel.getFaderTransition();
}

void keyPressed() {
  switch (key) {
    case 'a':
      if (datagrams.length > 0) {
        boolean toEnable = !datagrams[0].enabled.isOn();
        for (LXDatagram datagram : datagrams) {
          datagram.enabled.setValue(toEnable);
        }
      }
      break;
  }
}

