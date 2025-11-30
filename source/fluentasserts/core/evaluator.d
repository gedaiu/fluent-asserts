module fluentasserts.core.evaluator;

import fluentasserts.core.evaluation;
import fluentasserts.core.results;
import fluentasserts.core.base : TestException;

import std.functional : toDelegate;
import std.conv : to;

alias OperationFunc = IResult[] function(ref Evaluation) @safe nothrow;

@safe struct Evaluator {
    private {
        Evaluation evaluation;
        IResult[] delegate(ref Evaluation) @safe nothrow operation;
        int refCount;
    }

    this(Evaluation eval, OperationFunc op) @trusted {
        this.evaluation = eval;
        this.operation = op.toDelegate;
        this.refCount = 0;
    }

    this(ref return scope Evaluator other) {
        this.evaluation = other.evaluation;
        this.operation = other.operation;
        this.refCount = other.refCount + 1;
    }

    ~this() @trusted {
        refCount--;
        if (refCount < 0) {
            executeOperation();
        }
    }

    Evaluator because(string reason) {
        evaluation.message.prependText("Because " ~ reason ~ ", ");
        return this;
    }

    void inhibit() {
        this.refCount = int.max;
    }

    Throwable thrown() @trusted {
        executeOperation();
        return evaluation.throwable;
    }

    string msg() @trusted {
        executeOperation();
        if (evaluation.throwable is null) {
            return "";
        }
        return evaluation.throwable.msg.to!string;
    }

    private void executeOperation() @trusted {
        if (evaluation.isEvaluated) {
            return;
        }
        evaluation.isEvaluated = true;

        auto results = operation(evaluation);

        if (evaluation.currentValue.throwable !is null) {
            throw evaluation.currentValue.throwable;
        }

        if (evaluation.expectedValue.throwable !is null) {
            throw evaluation.expectedValue.throwable;
        }

        if (results.length == 0) {
            return;
        }

        version (DisableSourceResult) {
        } else {
            results ~= evaluation.source;
        }

        if (evaluation.message !is null) {
            results = evaluation.message ~ results;
        }

        throw new TestException(results, evaluation.source.file, evaluation.source.line);
    }
}
