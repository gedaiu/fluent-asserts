/// Evaluator structs for executing assertion operations.
/// Provides lifetime management and result handling for assertions.
module fluentasserts.core.evaluator;

import fluentasserts.core.evaluation;
import fluentasserts.core.lifecycle;
import fluentasserts.results.printer;
import fluentasserts.core.base : TestException;
import fluentasserts.results.serializers;
import fluentasserts.results.formatting : toNiceOperation;

import std.functional : toDelegate;
import std.conv : to;

alias OperationFunc = void function(ref Evaluation) @safe nothrow;
alias OperationFuncTrusted = void function(ref Evaluation) @trusted nothrow;
alias OperationFuncNoGC = void function(ref Evaluation) @safe nothrow @nogc;
alias OperationFuncTrustedNoGC = void function(ref Evaluation) @trusted nothrow @nogc;

@safe struct Evaluator {
    private {
        Evaluation _evaluation;
        void delegate(ref Evaluation) @safe nothrow operation;
        int refCount;
    }

    @disable this(this);

    this(ref Evaluation eval, OperationFuncNoGC op) @trusted {
        this._evaluation = eval;
        this.operation = op.toDelegate;
        this.refCount = 0;
    }

    this(ref Evaluation eval, OperationFunc op) @trusted {
        this._evaluation = eval;
        this.operation = op.toDelegate;
        this.refCount = 0;
    }

    this(ref return scope inout Evaluator other) @trusted {
        this._evaluation = other._evaluation;
        this.operation = cast(typeof(this.operation)) other.operation;
        this.refCount = other.refCount + 1;
    }

    ~this() @trusted {
        refCount--;
        if (refCount < 0) {
            executeOperation();
        }
    }

    ref Evaluator because(string reason) return {
        _evaluation.result.prependText("Because " ~ reason ~ ", ");
        return this;
    }

    void inhibit() nothrow @safe @nogc {
        this.refCount = int.max;
    }

    Throwable thrown() @trusted {
        executeOperation();
        return _evaluation.throwable;
    }

    string msg() @trusted {
        executeOperation();
        if (_evaluation.throwable is null) {
            return "";
        }
        return _evaluation.throwable.msg.to!string;
    }

    private void executeOperation() @trusted {
        if (_evaluation.isEvaluated) {
            return;
        }
        _evaluation.isEvaluated = true;

        if (_evaluation.currentValue.throwable !is null) {
            throw _evaluation.currentValue.throwable;
        }

        if (_evaluation.expectedValue.throwable !is null) {
            throw _evaluation.expectedValue.throwable;
        }

        operation(_evaluation);
        _evaluation.result.addText(".");

        if (Lifecycle.instance.keepLastEvaluation) {
            Lifecycle.instance.lastEvaluation = _evaluation;
        }

        if (!_evaluation.hasResult()) {
            return;
        }

        Lifecycle.instance.handleFailure(_evaluation);
    }
}

/// Evaluator for @trusted nothrow operations
@safe struct TrustedEvaluator {
    private {
        Evaluation _evaluation;
        void delegate(ref Evaluation) @trusted nothrow operation;
        int refCount;
    }

    @disable this(this);

    this(ref Evaluation eval, OperationFuncTrustedNoGC op) @trusted {
        this._evaluation = eval;
        this.operation = op.toDelegate;
        this.refCount = 0;
    }

    this(ref Evaluation eval, OperationFuncNoGC op) @trusted {
        this._evaluation = eval;
        this.operation = cast(void delegate(ref Evaluation) @trusted nothrow) op.toDelegate;
        this.refCount = 0;
    }

    this(ref Evaluation eval, OperationFuncTrusted op) @trusted {
        this._evaluation = eval;
        this.operation = op.toDelegate;
        this.refCount = 0;
    }

    this(ref Evaluation eval, OperationFunc op) @trusted {
        this._evaluation = eval;
        this.operation = cast(void delegate(ref Evaluation) @trusted nothrow) op.toDelegate;
        this.refCount = 0;
    }

    this(ref return scope inout TrustedEvaluator other) @trusted {
        this._evaluation = other._evaluation;
        this.operation = cast(typeof(this.operation)) other.operation;
        this.refCount = other.refCount + 1;
    }

    ~this() @trusted {
        refCount--;
        if (refCount < 0) {
            executeOperation();
        }
    }

    ref TrustedEvaluator because(string reason) return {
        _evaluation.result.prependText("Because " ~ reason ~ ", ");
        return this;
    }

    void inhibit() nothrow @safe @nogc {
        this.refCount = int.max;
    }

    private void executeOperation() @trusted {
        if (_evaluation.isEvaluated) {
            return;
        }
        _evaluation.isEvaluated = true;

        operation(_evaluation);
        _evaluation.result.addText(".");

        if (_evaluation.currentValue.throwable !is null) {
            throw _evaluation.currentValue.throwable;
        }

        if (_evaluation.expectedValue.throwable !is null) {
            throw _evaluation.expectedValue.throwable;
        }

        if (Lifecycle.instance.keepLastEvaluation) {
            Lifecycle.instance.lastEvaluation = _evaluation;
        }

        if (!_evaluation.hasResult()) {
            return;
        }

        Lifecycle.instance.handleFailure(_evaluation);
    }
}

/// Evaluator for throwable operations that can chain with withMessage
@safe struct ThrowableEvaluator {
    private {
        Evaluation _evaluation;
        void delegate(ref Evaluation) @trusted nothrow standaloneOp;
        void delegate(ref Evaluation) @trusted nothrow withMessageOp;
        int refCount;
        bool chainedWithMessage;
    }

    @disable this(this);

    this(ref Evaluation eval, OperationFuncTrusted standalone, OperationFuncTrusted withMsg) @trusted {
        this._evaluation = eval;
        this.standaloneOp = standalone.toDelegate;
        this.withMessageOp = withMsg.toDelegate;
        this.refCount = 0;
        this.chainedWithMessage = false;
    }

    this(ref return scope inout ThrowableEvaluator other) @trusted {
        this._evaluation = other._evaluation;
        this.standaloneOp = cast(typeof(this.standaloneOp)) other.standaloneOp;
        this.withMessageOp = cast(typeof(this.withMessageOp)) other.withMessageOp;
        this.refCount = other.refCount + 1;
        this.chainedWithMessage = other.chainedWithMessage;
    }

    ~this() @trusted {
        refCount--;
        if (refCount < 0 && !chainedWithMessage) {
            executeOperation(standaloneOp);
        }
    }

    ref ThrowableEvaluator withMessage() return {
        _evaluation.addOperationName("withMessage");
        _evaluation.result.addText(" with message");
        return this;
    }

    ref ThrowableEvaluator withMessage(T)(T message) return {
        _evaluation.addOperationName("withMessage");
        _evaluation.result.addText(" with message");

        auto expectedValue = message.evaluate.evaluation;
        foreach (kv; _evaluation.expectedValue.meta.byKeyValue) {
            expectedValue.meta[kv.key] = kv.value;
        }
        _evaluation.expectedValue = expectedValue;
        () @trusted { _evaluation.expectedValue.meta["0"] = SerializerRegistry.instance.serialize(message); }();

        if (!_evaluation.expectedValue.niceValue.empty) {
            _evaluation.result.addText(" ");
            _evaluation.result.addValue(_evaluation.expectedValue.niceValue[]);
        } else if (!_evaluation.expectedValue.strValue.empty) {
            _evaluation.result.addText(" ");
            _evaluation.result.addValue(_evaluation.expectedValue.strValue[]);
        }

        chainedWithMessage = true;
        executeOperation(withMessageOp);
        inhibit();
        return this;
    }

    ref ThrowableEvaluator equal(T)(T value) return {
        _evaluation.addOperationName("equal");

        auto expectedValue = value.evaluate.evaluation;
        foreach (kv; _evaluation.expectedValue.meta.byKeyValue) {
            expectedValue.meta[kv.key] = kv.value;
        }
        _evaluation.expectedValue = expectedValue;
        () @trusted { _evaluation.expectedValue.meta["0"] = SerializerRegistry.instance.serialize(value); }();

        _evaluation.result.addText(" equal");
        if (!_evaluation.expectedValue.niceValue.empty) {
            _evaluation.result.addText(" ");
            _evaluation.result.addValue(_evaluation.expectedValue.niceValue[]);
        } else if (!_evaluation.expectedValue.strValue.empty) {
            _evaluation.result.addText(" ");
            _evaluation.result.addValue(_evaluation.expectedValue.strValue[]);
        }

        chainedWithMessage = true;
        executeOperation(withMessageOp);
        inhibit();
        return this;
    }

    ref ThrowableEvaluator because(string reason) return {
        _evaluation.result.prependText("Because " ~ reason ~ ", ");
        return this;
    }

    void inhibit() nothrow @safe @nogc {
        this.refCount = int.max;
    }

    Throwable thrown() @trusted {
        executeOperation(standaloneOp);
        return _evaluation.throwable;
    }

    string msg() @trusted {
        executeOperation(standaloneOp);
        if (_evaluation.throwable is null) {
            return "";
        }
        return _evaluation.throwable.msg.to!string;
    }

    private void finalizeMessage() {
        _evaluation.result.addText(" ");
        _evaluation.result.addText(toNiceOperation(_evaluation.operationName));

        if (!_evaluation.expectedValue.niceValue.empty) {
            _evaluation.result.addText(" ");
            _evaluation.result.addValue(_evaluation.expectedValue.niceValue[]);
        } else if (!_evaluation.expectedValue.strValue.empty) {
            _evaluation.result.addText(" ");
            _evaluation.result.addValue(_evaluation.expectedValue.strValue[]);
        }
    }

    private void executeOperation(void delegate(ref Evaluation) @trusted nothrow op) @trusted {
        if (_evaluation.isEvaluated) {
            return;
        }
        _evaluation.isEvaluated = true;

        op(_evaluation);
        _evaluation.result.addText(".");

        if (_evaluation.currentValue.throwable !is null) {
            throw _evaluation.currentValue.throwable;
        }

        if (_evaluation.expectedValue.throwable !is null) {
            throw _evaluation.expectedValue.throwable;
        }

        if (Lifecycle.instance.keepLastEvaluation) {
            Lifecycle.instance.lastEvaluation = _evaluation;
        }

        if (!_evaluation.hasResult()) {
            return;
        }

        Lifecycle.instance.handleFailure(_evaluation);
    }
}
