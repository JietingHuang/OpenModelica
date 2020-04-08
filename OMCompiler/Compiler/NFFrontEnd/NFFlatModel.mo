/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype NFFlatModel
  import Equation = NFEquation;
  import Algorithm = NFAlgorithm;
  import Variable = NFVariable;

protected
  import Statement = NFStatement;
  import NFFunction.Function;
  import Expression = NFExpression;
  import Type = NFType;
  import NFBinding.Binding;
  import Dimension = NFDimension;
  import ComplexType = NFComplexType;
  import NFInstNode.InstNode;
  import IOStream;

  import FlatModel = NFFlatModel;

  type TypeTree = TypeTreeImpl.Tree;

  encapsulated package TypeTreeImpl
    import BaseAvlTree;
    import Absyn.Path;
    import NFType.Type;

    extends BaseAvlTree;
    redeclare type Key = Absyn.Path;
    redeclare type Value = Type;

    redeclare function extends keyStr
    algorithm
      outString := AbsynUtil.pathString(inKey);
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := Type.toString(inValue);
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := AbsynUtil.pathCompareNoQual(inKey1, inKey2);
    end keyCompare;

    redeclare function addConflictDefault = addConflictKeep;
  end TypeTreeImpl;

public
  record FLAT_MODEL
    String name;
    list<Variable> variables;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<Algorithm> algorithms;
    list<Algorithm> initialAlgorithms;
    Option<SCode.Comment> comment;
  end FLAT_MODEL;

  function toString
    input FlatModel flatModel;
    input Boolean printBindingTypes = false;
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());

    s := IOStream.append(s, "class " + flatModel.name + "\n");

    for v in flatModel.variables loop
      s := Variable.toStream(v, "  ", printBindingTypes, s);
      s := IOStream.append(s, ";\n");
    end for;

    if not listEmpty(flatModel.initialEquations) then
      s := IOStream.append(s, "initial equation\n");
      s := Equation.toStreamList(flatModel.initialEquations, "  ", s);
    end if;

    if not listEmpty(flatModel.equations) then
      s := IOStream.append(s, "equation\n");
      s := Equation.toStreamList(flatModel.equations, "  ", s);
    end if;

    for alg in flatModel.initialAlgorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "initial algorithm\n");
        s := Statement.toStreamList(alg.statements, "  ", s);
      end if;
    end for;

    for alg in flatModel.algorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "algorithm\n");
        s := Statement.toStreamList(alg.statements, "  ", s);
      end if;
    end for;

    s := IOStream.append(s, "end " + flatModel.name + ";\n");

    str := IOStream.string(s);
    IOStream.delete(s);
  end toString;

  function toFlatString
    input FlatModel flatModel;
    input list<Function> functions;
    input Boolean printBindingTypes = false;
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toFlatStream(flatModel, functions, printBindingTypes, s);
    str := IOStream.string(s);
  end toFlatString;

  function printFlatString
    input FlatModel flatModel;
    input list<Function> functions;
    input Boolean printBindingTypes = false;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toFlatStream(flatModel, functions, printBindingTypes, s);
    IOStream.print(s, IOStream.stdOutput);
  end printFlatString;

  function toFlatStream
    input FlatModel flatModel;
    input list<Function> functions;
    input Boolean printBindingTypes = false;
    input output IOStream.IOStream s;
    output String str;
  algorithm
    for fn in functions loop
      if not Function.isDefaultRecordConstructor(fn) then
        s := Function.toFlatStream(fn, s);
        s := IOStream.append(s, ";\n\n");
      end if;
    end for;

    for ty in TypeTree.listValues(collectFlatTypes(flatModel)) loop
      s := Type.toFlatDeclarationStream(ty, s);
      s := IOStream.append(s, ";\n\n");
    end for;

    s := IOStream.append(s, "class '" + flatModel.name + "'\n");

    for v in flatModel.variables loop
      s := Variable.toFlatStream(v, "  ", printBindingTypes, s);
      s := IOStream.append(s, ";\n");
    end for;

    if not listEmpty(flatModel.initialEquations) then
      s := IOStream.append(s, "initial equation\n");
      s := Equation.toFlatStreamList(flatModel.initialEquations, "  ", s);
    end if;

    if not listEmpty(flatModel.equations) then
      s := IOStream.append(s, "equation\n");
      s := Equation.toFlatStreamList(flatModel.equations, "  ", s);
    end if;

    for alg in flatModel.initialAlgorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "initial algorithm\n");
        s := Statement.toFlatStreamList(alg.statements, "  ", s);
      end if;
    end for;

    for alg in flatModel.algorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "algorithm\n");
        s := Statement.toFlatStreamList(alg.statements, "  ", s);
      end if;
    end for;

    s := IOStream.append(s, "end '" + flatModel.name + "';\n");

    str := IOStream.string(s);
    IOStream.delete(s);
  end toFlatStream;

  function collectFlatTypes
    input FlatModel flatModel;
    output TypeTree types;
  algorithm
    types := TypeTree.new();
    types := List.fold(flatModel.variables, collectComponentFlatTypes, types);
    types := List.fold(flatModel.equations, collectEquationFlatTypes, types);
    types := List.fold(flatModel.initialEquations, collectEquationFlatTypes, types);
    types := List.fold(flatModel.algorithms, collectAlgorithmFlatTypes, types);
    types := List.fold(flatModel.initialAlgorithms, collectAlgorithmFlatTypes, types);
  end collectFlatTypes;

  function collectComponentFlatTypes
    input Variable var;
    input output TypeTree types;
  algorithm
    types := collectFlatType(var.ty, types);
    types := collectBindingFlatTypes(var.binding, types);

    for attr in var.typeAttributes loop
      types := collectBindingFlatTypes(Util.tuple22(attr), types);
    end for;
  end collectComponentFlatTypes;

  function collectFlatType
    input Type ty;
    input output TypeTree types;
  algorithm
    () := match ty
      case Type.ENUMERATION()
        algorithm
          types := TypeTree.add(types, ty.typePath, ty);
        then
          ();

      case Type.ARRAY()
        algorithm
          types := Dimension.foldExpList(ty.dimensions, collectExpFlatTypes_traverse, types);
          types := collectFlatType(ty.elementType, types);
        then
          ();

      case Type.COMPLEX(complexTy = ComplexType.RECORD())
        algorithm
          types := TypeTree.add(types, InstNode.scopePath(ty.cls), ty);
        then
          ();

      else ();
    end match;
  end collectFlatType;

  function collectBindingFlatTypes
    input Binding binding;
    input output TypeTree types;
  algorithm
    if Binding.isExplicitlyBound(binding) then
      types := collectExpFlatTypes(Binding.getTypedExp(binding), types);
    end if;
  end collectBindingFlatTypes;

  function collectEquationFlatTypes
    input Equation eq;
    input output TypeTree types;
  algorithm
    () := match eq
      case Equation.EQUALITY()
        algorithm
          types := collectExpFlatTypes(eq.lhs, types);
          types := collectExpFlatTypes(eq.rhs, types);
          types := collectFlatType(eq.ty, types);
        then
          ();

      case Equation.ARRAY_EQUALITY()
        algorithm
          types := collectExpFlatTypes(eq.lhs, types);
          types := collectExpFlatTypes(eq.rhs, types);
          types := collectFlatType(eq.ty, types);
        then
          ();

      case Equation.FOR()
        algorithm
          types := List.fold(eq.body, collectEquationFlatTypes, types);
        then
          ();

      case Equation.IF()
        algorithm
          types := List.fold(eq.branches, collectEqBranchFlatTypes, types);
        then
          ();

      case Equation.WHEN()
        algorithm
          types := List.fold(eq.branches, collectEqBranchFlatTypes, types);
        then
          ();

      case Equation.ASSERT()
        algorithm
          types := collectExpFlatTypes(eq.condition, types);
          types := collectExpFlatTypes(eq.message, types);
          types := collectExpFlatTypes(eq.level, types);
        then
          ();

      case Equation.TERMINATE()
        algorithm
          types := collectExpFlatTypes(eq.message, types);
        then
          ();

      case Equation.REINIT()
        algorithm
          types := collectExpFlatTypes(eq.reinitExp, types);
        then
          ();

      case Equation.NORETCALL()
        algorithm
          types := collectExpFlatTypes(eq.exp, types);
        then
          ();

      else ();
    end match;
  end collectEquationFlatTypes;

  function collectEqBranchFlatTypes
    input Equation.Branch branch;
    input output TypeTree types;
  algorithm
    () := match branch
      case Equation.Branch.BRANCH()
        algorithm
          types := collectExpFlatTypes(branch.condition, types);
          types := List.fold(branch.body, collectEquationFlatTypes, types);
        then
          ();

      else ();
    end match;
  end collectEqBranchFlatTypes;

  function collectAlgorithmFlatTypes
    input Algorithm alg;
    input output TypeTree types;
  algorithm
    types := List.fold(alg.statements, collectStatementFlatTypes, types);
  end collectAlgorithmFlatTypes;

  function collectStatementFlatTypes
    input Statement stmt;
    input output TypeTree types;
  algorithm
    () := match stmt
      case Statement.ASSIGNMENT()
        algorithm
          types := collectExpFlatTypes(stmt.lhs, types);
          types := collectExpFlatTypes(stmt.rhs, types);
          types := collectFlatType(stmt.ty, types);
        then
          ();

      case Statement.FOR()
        algorithm
          types := List.fold(stmt.body, collectStatementFlatTypes, types);
          types := collectExpFlatTypes(Util.getOption(stmt.range), types);
        then
          ();

      case Statement.IF()
        algorithm
          types := List.fold(stmt.branches, collectStmtBranchFlatTypes, types);
        then
          ();

      case Statement.WHEN()
        algorithm
          types := List.fold(stmt.branches, collectStmtBranchFlatTypes, types);
        then
          ();

      case Statement.ASSERT()
        algorithm
          types := collectExpFlatTypes(stmt.condition, types);
          types := collectExpFlatTypes(stmt.message, types);
          types := collectExpFlatTypes(stmt.level, types);
        then
          ();

      case Statement.TERMINATE()
        algorithm
          types := collectExpFlatTypes(stmt.message, types);
        then
          ();

      case Statement.NORETCALL()
        algorithm
          types := collectExpFlatTypes(stmt.exp, types);
        then
          ();

      case Statement.WHILE()
        algorithm
          types := collectExpFlatTypes(stmt.condition, types);
          types := List.fold(stmt.body, collectStatementFlatTypes, types);
        then
          ();

      else ();
    end match;
  end collectStatementFlatTypes;

  function collectStmtBranchFlatTypes
    input tuple<Expression, list<Statement>> branch;
    input output TypeTree types;
  algorithm
    types := collectExpFlatTypes(Util.tuple21(branch), types);
    types := List.fold(Util.tuple22(branch), collectStatementFlatTypes, types);
  end collectStmtBranchFlatTypes;

  function collectExpFlatTypes
    input Expression exp;
    input output TypeTree types;
  algorithm
    types := Expression.fold(exp, collectExpFlatTypes_traverse, types);
  end collectExpFlatTypes;

  function collectExpFlatTypes_traverse
    input Expression exp;
    input output TypeTree types;
  algorithm
    types := collectFlatType(Expression.typeOf(exp), types);
  end collectExpFlatTypes_traverse;

  annotation(__OpenModelica_Interface="frontend");
end NFFlatModel;
