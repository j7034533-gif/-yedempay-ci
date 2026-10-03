"use client";
import { FormEvent, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Logo } from "@/components/Logo";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function LoginPage(){
  const supabase=createClient(); const router=useRouter();
  const [email,setEmail]=useState(""); const [password,setPassword]=useState(""); const [error,setError]=useState(""); const [loading,setLoading]=useState(false);
  async function submit(e:FormEvent){e.preventDefault();setLoading(true);setError("");
    const {error}=await supabase.auth.signInWithPassword({email,password});
    if(error){setError(error.message==="Invalid login credentials"?"Email ou mot de passe incorrect.":error.message);setLoading(false);return;}
    router.replace("/dashboard"); router.refresh();
  }
  return <main className="grid min-h-screen place-items-center bg-slate-50 p-4">
    <form onSubmit={submit} className="w-full max-w-md rounded-2xl border bg-white p-7 shadow-sm">
      <div className="mb-7"><Logo/></div>
      <h1 className="text-2xl font-bold text-slate-900">Connexion</h1>
      <p className="mt-1 text-sm text-slate-500">Accédez à la gestion des paiements de votre école.</p>
      <div className="mt-6 space-y-4">
        <input required type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="Email" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-blue-500"/>
        <input required type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="Mot de passe" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-blue-500"/>
        {error&&<p className="rounded-xl bg-red-50 p-3 text-sm text-red-700">{error}</p>}
        <button disabled={loading} className="w-full rounded-xl bg-blue-600 px-4 py-3 font-semibold text-white disabled:opacity-60">{loading?"Connexion…":"Se connecter"}</button>
      </div>
      <p className="mt-5 text-center text-sm text-slate-500">Nouvelle école ? <Link className="font-semibold text-blue-600" href="/inscription">Créer un compte</Link></p>
    </form>
  </main>
}