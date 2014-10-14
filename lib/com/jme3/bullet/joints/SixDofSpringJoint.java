/*
 * Copyright (c) 2009-2012 jMonkeyEngine
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the name of 'jMonkeyEngine' nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package com.jme3.bullet.joints;

import java.io.IOException;

import com.bulletphysics.dynamics.constraintsolver.Generic6DofConstraint;
import com.bulletphysics.dynamics.constraintsolver.Generic6DofSpringConstraint;
import com.jme3.bullet.objects.PhysicsRigidBody;
import com.jme3.export.InputCapsule;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.export.OutputCapsule;
import com.jme3.math.Matrix3f;
import com.jme3.math.Vector3f;

/**
 * Generic 6 DOF constraint that allows to set spring motors to any translational and rotational DOF
 * DOF index used in enableSpring() and setStiffness() means:
 *    0 : translation X
 *    1 : translation Y
 *    2 : translation Z
 *    3 : rotation X (3rd Euler rotational around new position of X axis, range [-PI+epsilon, PI-epsilon] )
 *    4 : rotation Y (2nd Euler rotational around new position of Y axis, range [-PI/2+epsilon, PI/2-epsilon] )
 *    5 : rotation Z (1st Euler rotational around Z axis, range [-PI+epsilon, PI-epsilon] )
 *
 * @author davidB
 */
public class SixDofSpringJoint extends SixDofJoint {
	private final boolean[] springS = new boolean[]{false, false, false, false, false, false};
	private final float[] stiffnessS = new float[]{-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
	private final float[] dampingS = new float[]{-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
	
    public SixDofSpringJoint() {
    }

    /**
     * @param pivotA local translation of the joint connection point in node A
     * @param pivotB local translation of the joint connection point in node B
     */
    public SixDofSpringJoint(PhysicsRigidBody nodeA, PhysicsRigidBody nodeB, Vector3f pivotA, Vector3f pivotB, Matrix3f rotA, Matrix3f rotB, boolean useLinearReferenceFrameA) {
        super(nodeA, nodeB, pivotA, pivotB, rotA, rotB, useLinearReferenceFrameA);
        constraint = new Generic6DofSpringConstraint((Generic6DofConstraint)constraint);
    }

    public void enableSpring(int index, boolean onOff) {
        assert (index >= 0) && (index < 6);
        springS[index] = onOff;
    	((Generic6DofSpringConstraint)constraint).enableSpring(index, onOff);
    }
    
    public void setStiffness(int index, float stiffness) {
        assert (index >= 0) && (index < 6);
        stiffnessS[index] = stiffness;
    	((Generic6DofSpringConstraint)constraint).setStiffness(index, stiffness);
    }

    public void setDamping(int index, float damping) {
        assert (index >= 0) && (index < 6);
        dampingS[index] = damping;
    	((Generic6DofSpringConstraint)constraint).setDamping(index, damping);
    }

    /**
     *  set the current constraint position/orientation as an equilibrium point for all DOF
     */
    public void setEquilibriumPoint() { 
    	((Generic6DofSpringConstraint)constraint).setEquilibriumPoint();
    }

    /**
     * set the current constraint position/orientation as an equilibrium point for given DOF
     * @param index
     */
    public void setEquilibriumPoint(int index){ 
    	((Generic6DofSpringConstraint)constraint).setEquilibriumPoint(index);
    }

    @Override
    public void read(JmeImporter im) throws IOException {
        super.read(im);
        InputCapsule capsule = im.getCapsule(this);
        boolean[] spring0 = capsule.readBooleanArray("spring", springS);
        for(int i = 0; i < spring0.length; i++) {
        	enableSpring(i, spring0[i]);
        }
        float[] stiffness0 = capsule.readFloatArray("stiffness", stiffnessS);
        for(int i = 0; i < stiffness0.length; i++) {
        	setStiffness(i, stiffness0[i]);
        }
        float[] damping0 = capsule.readFloatArray("damping", dampingS);
        for(int i = 0; i < damping0.length; i++) {
        	setDamping(i, damping0[i]);
        }
    }

    @Override
    public void write(JmeExporter ex) throws IOException {
        super.write(ex);
        OutputCapsule capsule = ex.getCapsule(this);
        capsule.write(springS, "spring", springS);
        capsule.write(stiffnessS, "stiffness", stiffnessS);
        capsule.write(dampingS, "damping", dampingS);
    }    
}
