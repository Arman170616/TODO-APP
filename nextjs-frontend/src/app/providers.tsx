"use client";

import { GoogleOAuthProvider } from "@react-oauth/google";

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <GoogleOAuthProvider clientId="140560791771-j78sejqcc5f3roeq0te6cput1fi6c062.apps.googleusercontent.com">
      {children}
    </GoogleOAuthProvider>
  );
}
