import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import path from "path"

const execAsync = promisify(exec)

export async function POST(request: Request) {
  try {
    const { name, type, description } = await request.json()

    // Validation
    if (!name || !type) {
      return NextResponse.json(
        { error: "Tool name and type are required" },
        { status: 400 }
      )
    }

    // Validate tool name format
    if (!/^[a-z0-9-]+$/.test(name)) {
      return NextResponse.json(
        { error: "Tool name must contain only lowercase letters, numbers, and hyphens" },
        { status: 400 }
      )
    }

    const skillsDir = path.join(process.env.HOME || "", ".openclaw", "workspace", "skills")
    const scriptPath = path.join(skillsDir, "mission-control", "scripts", "mission_control.py")

    // Execute the Python script
    const { stdout, stderr } = await execAsync(
      `python "${scriptPath}" create ${name} --type ${type} --path "${skillsDir}"`
    )

    if (stderr) {
      console.error("Script error:", stderr)
    }

    return NextResponse.json({
      success: true,
      message: "Tool created successfully",
      output: stdout,
    })
  } catch (error) {
    console.error("Error creating tool:", error)
    return NextResponse.json(
      { error: "Failed to create tool", details: (error as Error).message },
      { status: 500 }
    )
  }
}
