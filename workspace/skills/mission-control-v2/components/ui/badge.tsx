import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import * as React from "react"

import { cn } from "@/lib/utils"

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2 py-0.5 text-xs font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "border-transparent bg-white/[0.08] text-white/70 hover:bg-white/[0.12]",
        secondary:
          "border-transparent bg-white/[0.06] text-white/50 hover:bg-white/[0.08]",
        destructive:
          "border-transparent bg-red-500/10 text-red-400 hover:bg-red-500/20",
        outline: "text-white/50 border-white/[0.08]",
        purple: "border-transparent bg-purple-500/10 text-purple-400",
        blue: "border-transparent bg-blue-500/10 text-blue-400",
        green: "border-transparent bg-green-500/10 text-green-400",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {
  asChild?: boolean
}

function Badge({ className, variant, asChild = false, ...props }: BadgeProps) {
  const Comp = asChild ? Slot : "div"
  return (
    <Comp className={cn(badgeVariants({ variant }), className)} {...props} />
  )
}

export { Badge, badgeVariants }
