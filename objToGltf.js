const { exec } = require("child_process");
const { promisify } = require("util");
const fs = require("fs");
const path = require("path");

const execAsync = promisify(exec);

/**
 * OBJ 파일을 glTF 파일로 변환하는 함수
 * @param {string} inputPath - 입력 OBJ 파일 경로
 * @param {string} outputPath - 출력 glTF 파일 경로 (선택사항, 지정하지 않으면 입력 파일과 같은 디렉토리에 .gltf 확장자로 저장)
 * @param {object} options - 변환 옵션 (선택사항)
 * @returns {Promise<string>} - 출력 파일 경로를 반환하는 Promise
 */
async function convertObjToGltf(inputPath, outputPath = null, options = {}) {
  // 변환 시작 시간 측정
  const startTime = process.hrtime.bigint();
  
  try {
    // 입력 파일 경로 검증
    if (!fs.existsSync(inputPath)) {
      throw new Error(`Input file not found: ${inputPath}`);
    }

    // 출력 경로가 지정되지 않은 경우 자동 생성
    if (!outputPath) {
      const inputDir = path.dirname(inputPath);
      const inputName = path.basename(inputPath, path.extname(inputPath));
      outputPath = path.join(inputDir, `${inputName}.gltf`);
    }

    // obj2gltf CLI 경로 찾기
    const obj2gltfPath = require.resolve("obj2gltf/bin/obj2gltf.js");
    
    // 옵션을 CLI 인자로 변환
    const args = [];
    args.push(`-i "${inputPath}"`);
    args.push(`-o "${outputPath}"`);
    
    if (options.binary) {
      args.push("-b");
    }
    if (options.separate) {
      args.push("-s");
    }
    if (options.separateTextures) {
      args.push("-t");
    }
    if (options.checkTransparency) {
      args.push("--checkTransparency");
    }
    if (options.secure) {
      args.push("--secure");
    }
    if (options.packOcclusion) {
      args.push("--packOcclusion");
    }
    if (options.metallicRoughness) {
      args.push("--metallicRoughness");
    }
    if (options.specularGlossiness) {
      args.push("--specularGlossiness");
    }
    if (options.unlit) {
      args.push("--unlit");
    }

    // obj2gltf CLI 실행
    const command = `node "${obj2gltfPath}" ${args.join(" ")}`;
    const { stdout, stderr } = await execAsync(command);

    if (stderr && !stderr.includes("Warning")) {
      console.warn(stderr);
    }

    // 변환 완료 시간 측정
    const endTime = process.hrtime.bigint();
    const durationNs = endTime - startTime;
    const durationMs = Number(durationNs) / 1000000; // 나노초를 밀리초로 변환
    const durationSec = durationMs / 1000; // 밀리초를 초로 변환

    console.log(`Successfully converted ${inputPath} to ${outputPath}`);
    console.log(`변환 소요 시간: ${durationMs.toFixed(2)}ms (${durationSec.toFixed(2)}s)`);
    
    return outputPath;
  } catch (error) {
    // 에러 발생 시에도 시간 측정
    const endTime = process.hrtime.bigint();
    const durationNs = endTime - startTime;
    const durationMs = Number(durationNs) / 1000000;
    const durationSec = durationMs / 1000;
    
    console.error(`Error converting OBJ to glTF: ${error.message}`);
    console.error(`실패까지 소요 시간: ${durationMs.toFixed(2)}ms (${durationSec.toFixed(2)}s)`);
    throw error;
  }
}

// Command line interface
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error("사용법: node objToGltf.js <input.obj> [output.gltf]");
    console.error("예시: node objToGltf.js assets/1/model.obj assets/1/model.gltf");
    console.error("예시: node objToGltf.js assets/1/model.obj  (출력 경로 자동 생성)");
    process.exit(1);
  }

  const inputFile = path.resolve(args[0]);
  const outputFile = args[1] ? path.resolve(args[1]) : null;

  // 전체 실행 시간 측정 (CLI 모드)
  const cliStartTime = process.hrtime.bigint();
  
  convertObjToGltf(inputFile, outputFile)
    .then((outputPath) => {
      const cliEndTime = process.hrtime.bigint();
      const cliDurationNs = cliEndTime - cliStartTime;
      const cliDurationMs = Number(cliDurationNs) / 1000000;
      const cliDurationSec = cliDurationMs / 1000;
      
      console.log(`Conversion completed: ${outputPath}`);
      console.log(`전체 실행 시간: ${cliDurationMs.toFixed(2)}ms (${cliDurationSec.toFixed(2)}s)`);
    })
    .catch((error) => {
      const cliEndTime = process.hrtime.bigint();
      const cliDurationNs = cliEndTime - cliStartTime;
      const cliDurationMs = Number(cliDurationNs) / 1000000;
      const cliDurationSec = cliDurationMs / 1000;
      
      console.error(`Conversion failed:`, error);
      console.error(`전체 실행 시간: ${cliDurationMs.toFixed(2)}ms (${cliDurationSec.toFixed(2)}s)`);
      process.exit(1);
    });
}

module.exports = convertObjToGltf;

