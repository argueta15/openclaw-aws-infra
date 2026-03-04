import { EC2Client, RunInstancesCommand } from "@aws-sdk/client-ec2";

const ec2 = new EC2Client({});

export const handler = async (event) => {
  console.log("Recibiendo SQS Event: ", JSON.stringify(event));

  // Sacamos cuántos jobs llegaron en este batch para saber cuántos workers levantar
  // (En un caso real, puedes limitar para no levantar más de X)
  const jobCount = event.Records.length;

  const params = {
    ImageId: process.env.WORKER_AMI_ID,
    InstanceType: process.env.WORKER_INSTANCE_TYPE,
    MinCount: jobCount,
    MaxCount: jobCount,
    SecurityGroupIds: [process.env.SECURITY_GROUP_ID],
    SubnetId: process.env.SUBNET_ID,
    InstanceInitiatedShutdownBehavior: "terminate", // Mágico: si se apaga el OS, la máquina desaparece y deja de cobrar
    InstanceMarketOptions: {
      MarketType: "spot", // Spot para costo $0.004 a $0.02
    },
    UserData: Buffer.from(`#!/bin/bash
# User data script del worker:
# 1. Ejecutar el job leyendo de SQS...
# 2. Cuando termine:
shutdown -h now
`).toString("base64"),
    TagSpecifications: [
      {
        ResourceType: "instance",
        Tags: [
          { Key: "Name", Value: "OpenClaw-Spot-Worker" },
          { Key: "Role", Value: "Worker" }
        ],
      },
    ],
  };

  try {
    const data = await ec2.send(new RunInstancesCommand(params));
    console.log("Spot instances launched: ", data.Instances.map(i => i.InstanceId));
  } catch (err) {
    console.error("Error launching spot instance", err);
    throw err;
  }
};
