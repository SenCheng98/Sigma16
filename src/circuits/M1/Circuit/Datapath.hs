-- Sigma16: Datapath.hs
-- Copyright (C) 2020 John T. O'Donnell
-- email: john.t.odonnell9@gmail.com
-- License: GNU GPL Version 3 or later
-- See Sigma16/COPYRIGHT.txt, Sigma16/LICENSE.txt

-- This file is part of Sigma16.  Sigma16 is free software: you can
-- redistribute it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation, either
-- version 3 of the License, or (at your option) any later version.
-- Sigma16 is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- General Public License for more details.  You should have received
-- a copy of the GNU General Public License along with Sigma16.  If
-- not, see <https://www.gnu.org/licenses/>.

------------------------------------------------------------------------
--			       Datapath
------------------------------------------------------------------------

module M1.Circuit.Datapath where

{- This module defines a basic datapath that supports a subset of the
Sigma16 architecture.  The datapath contains a ripple carry adder
instead of a full ALU.  It can be simulated using RunDatapath1. -}

import HDL.Hydra.Core.Lib
import HDL.Hydra.Circuits.Combinational
import HDL.Hydra.Circuits.Register

import M1.Circuit.RegFile
import M1.Circuit.ControlSignals
import M1.Circuit.ALU

{- The datapath contains the registers, computational systems, and
interconnections.  It has two inputs: a set of control signals
provided by the control unit, and a data word from the either the
memory system or the DMA input controller. -}

datapath
  :: CBit a
  => CtlSig a
  -> [a]
  -> (([a],[a],a),  -- alu outputs (r, ccnew, condcc)
      [a],   -- ma
      [a],   -- md
      [a],   -- a
      [a],   -- b
      [a],   -- cc
      [a],   -- ir
      ([a],[a],[a],[a]),  -- irFields
      [a],   -- pc
      [a],   -- ad
      [a],   -- x
      [a],   -- y
      [a],   -- p
      [a]   -- q
     )
  
-- datapath ctlsigs memdat = (aluOutputs,ma,md,a,b,cc,ir,irFields,
--                              pc,ad,r,x,y,p,condcc,q)

datapath ctlsigs memdat = (aluOutputs,ma,md,a,b,cc,ir,irFields,pc,ad,x,y,p,q)
  where

-- Size parameters
      n = 16    -- word size
--    k =  4    -- the register file contains 2^k registers 

-- Registers
      (a,b,cc) = regFileSpec n (ctl_rf_ld ctlsigs) (ctl_rf_ldcc ctlsigs)
                    ir_d rf_sa rf_sb
                    p ccnew
      ir = reg n (ctl_ir_ld ctlsigs) memdat
      pc = reg n (ctl_pc_ld ctlsigs) q
      ad = reg n (ctl_ad_ld ctlsigs) (mux1w (ctl_ad_alu ctlsigs) memdat r)

-- The ALU
      aluOutputs = alu n (ctl_alu_a ctlsigs, ctl_alu_b ctlsigs) x y cc ir_d
      (r,ccnew,condcc) = aluOutputs
      
-- Internal processor signals
      x = mux1w (ctl_x_pc ctlsigs) a pc             -- alu input 1
      y = mux1w (ctl_y_ad ctlsigs) b ad             -- alu input 2
      rf_sa = mux1w (ctl_rf_sd ctlsigs) ir_sa ir_d  -- a = reg[rf_sa]
      rf_sb = ir_sb                                 -- b = reg[rf_sb]
      p  = mux1w (ctl_rf_pc ctlsigs)                -- regfile data input
             (mux1w (ctl_rf_alu ctlsigs) memdat r)
             pc
      q = mux1w (ctl_pc_ad ctlsigs) r ad        -- input to pc
      ma = mux1w (ctl_ma_pc ctlsigs) ad pc      -- memory address
      md = ad                                    -- memory data

-- Instruction fields
      ir_op = field ir  0 4           -- instruction opcode
      ir_d  = field ir  4 4           -- instruction destination register
      ir_sa = field ir  8 4           -- instruction source a register
      ir_sb = field ir 12 4           -- instruction source b register
      irFields = (ir_op,ir_d,ir_sa,ir_sb)
