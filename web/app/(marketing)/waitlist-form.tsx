"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { submitWaitlist, type WaitlistFormState } from "./actions";

const initialState: WaitlistFormState = { status: "idle" };

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="rounded-md bg-foreground px-5 py-3 text-sm font-medium text-background transition hover:opacity-90 disabled:opacity-50"
    >
      {pending ? "Joining..." : "Join the waitlist"}
    </button>
  );
}

export function WaitlistForm() {
  const [state, formAction] = useActionState(submitWaitlist, initialState);

  if (state.status === "ok") {
    return (
      <p className="text-sm text-(--color-accent)" role="status">
        You&apos;re on the list. We&apos;ll email when the iOS app opens up.
      </p>
    );
  }

  return (
    <form action={formAction} className="flex flex-col gap-3 sm:flex-row">
      <label htmlFor="email" className="sr-only">
        Email address
      </label>
      <input
        id="email"
        type="email"
        name="email"
        required
        autoComplete="email"
        placeholder="you@example.com"
        className="flex-1 rounded-md border border-(--color-border) bg-background px-4 py-3 text-sm placeholder:text-(--color-muted-foreground) focus:border-foreground focus:outline-none"
      />
      <input type="hidden" name="source" value="landing" />
      <SubmitButton />
      {state.status === "error" && (
        <p className="text-sm text-red-600 sm:basis-full" role="alert">
          {state.message}
        </p>
      )}
    </form>
  );
}
