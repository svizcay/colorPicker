#version 330 core

uniform vec2 circleOrigin;	// in model space
uniform vec2 radius;		// in model space
uniform vec2 windowSize;	// in window space
uniform vec2 clickPos;		// in window space

/*
	gl_FragCoord: coord in window space
*/
layout(origin_upper_left, pixel_center_integer) in vec4 gl_FragCoord;
// layout(pixel_center_integer) in vec4 gl_FragCoord;

out vec4 color;

// function declarations
void rgb2hsv(in vec3 rgb, out vec3 hsv);
void hsv2rgb(in vec3 hsv, out vec3 rgb);
float getMin(in float a, in float b, in float c);
float getMax(in float a, in float b, in float c);

vec2 getNDCFromWindowCoord(vec2 windowCoord);
float getAngleFromNDC(vec2 ndc);
float getDegreeFromWindowSpace(vec2 windowCoord);
float getTestValue(float channel, float temp1, float temp2);
vec3 getRGBfromAngleSaturationLuminance(float angle, float saturation, float luminance);
vec3 getRGBfromAngle(float angle);
float getSaturationFromNDC(vec2 ndc);
float getLuminanceFromNDC(vec2 ndc);
float getValueFromNDC(vec2 ndc);


vec2 getNDCFromWindowCoord(vec2 windowCoord)
{
	vec2 ndc = vec2(1);
	ndc.x = 2.0f / windowSize.x * windowCoord.x - 1;
	ndc.y = -2.0f / windowSize.y * windowCoord.y + 1;
	return ndc;
}

float getAngleFromNDC(vec2 ndc)
{
	float angle = atan(ndc.y, ndc.x);
	if (angle < 0) {
		angle = 2 * 3.1415 + angle;
	}
	angle = degrees(angle);

	return angle;
}

float getDegreeFromWindowSpace(vec2 windowCoord)
{
	vec2 ndc = getNDCFromWindowCoord(windowCoord);
	float angle = getAngleFromNDC(ndc);
	return angle;
}

vec3 getRGBfromAngleSaturationLuminance(float angle, float saturation, float luminance)
{
	float tempHue = angle / 360.0;
	float tempR = tempHue + 0.333;
	float tempG = tempHue;
	float tempB = tempHue - 0.333;

	if (tempR > 1) tempR -= 1;
	if (tempG > 1) tempG -= 1;
	if (tempB > 1) tempB -= 1;

	if (tempR < 0) tempR += 1;
	if (tempG < 0) tempG += 1;
	if (tempB < 0) tempB += 1;

	float temp1 = 0;
	float temp2 = 0;
	if (luminance < 0.5) {
		temp1 = luminance * (1 + saturation);
	} else {
		temp1 = luminance + saturation - (luminance * saturation);
	}
	temp2 = 2 * luminance - temp1;

	float red = getTestValue(tempR, temp1, temp2);
	float green = getTestValue(tempG, temp1, temp2);
	float blue = getTestValue(tempB, temp1, temp2);

	vec3 rgb = vec3(red, green, blue);
	return rgb;

}

vec3 getRGBfromAngle(float angle)
{
	vec3 rgb = getRGBfromAngleSaturationLuminance(angle, 1, 0.5);
	return rgb;
}

float getTestValue(float channel, float temp1, float temp2)
{
	float output = 0;
	if (6 * channel < 1) {
		output = temp2 + (temp1-temp2) * 6 * channel;
	} else {
		if (2 * channel < 1) {
			output = temp1 + (temp1-temp2) * 6 * channel;
		} else {
			if (3 * channel < 2) {
				output = temp2 + (temp1-temp2) * (0.666 - channel) * 6;
			} else {
				output = temp2;
			}
		}
	}

	return output;

}

void rgb2hsv(in vec3 rgb, out vec3 hsv)
{
	float minValue, maxValue, delta;
	minValue = getMin(rgb.r, rgb.g, rgb.b);
	maxValue = getMax(rgb.r, rgb.g, rgb.b);
	delta = maxValue - minValue;

	// hsv.v = hsv.z
	hsv.z = maxValue;

	// hsv.s = hsv.y
	// hsv.h = hsv.x
	if (maxValue != 0) {
		hsv.y = delta / maxValue;
	} else {
		hsv.y = 0;
		hsv.x = -1;
		return;
	}

	if (rgb.r == maxValue) {
		hsv.x = ((rgb.g - rgb.b) / delta);
	} else if (rgb.g == maxValue) {
		hsv.x = 2 + (rgb.b - rgb.r) / delta;
	} else if (rgb.b == maxValue) {
		hsv.x = 4 + (rgb.r - rgb.g) / delta;
	}

	hsv.x = hsv.x * 60;
	if (hsv.x < 0) {
		hsv.x = hsv.x + 360;
	}
}

void hsv2rgb(in vec3 hsv, out vec3 rgb)
{
	int i;
	float f, p, q, t;
	if (hsv.s == 0) {
		// achromatic (grey) hsv.z == hsv.v
		rgb.r = hsv.z;
		rgb.g = hsv.z;
		rgb.b = hsv.z;
		return;
	}

	// hsv.h = hsv.x
	hsv.x = hsv.x / 60;
	i = int(floor(hsv.x));
	f = hsv.x - i;	// decimal part of h
	// hsv.v = hsv.z
	// hsv.s = hsv.y
	p = hsv.z * (1 - hsv.y);
	q = hsv.z * (1 - hsv.y * f);
	t = hsv.z * (1 - hsv.y * (1 - f));
	switch(i) {
		case 0:
			rgb.r = hsv.z;
			rgb.g = t;
			rgb.b = p;
			break;
		case 1:
			rgb.r = q;
			rgb.g = hsv.z;
			rgb.b = p;
			break;
		case 2:
			rgb.r = p;
			rgb.g = hsv.z;
			rgb.b = t;
			break;
		case 3:
			rgb.r = p;
			rgb.g = q;
			rgb.b = hsv.z;
			break;
		case 4:
			rgb.r = t;
			rgb.g = p;
			rgb.b = hsv.z;
			break;
		default:        // case 5:
			rgb.r = hsv.z;
			rgb.g = p;
			rgb.b = q;
			break;
	}
}

float getMin(in float a, in float b, in float c)
{
	float minValue;
	if (a < b) {
		if (a < c) {
			minValue = a;
		} else {
			minValue = c;
		}
	} else {
		if (b < c) {
			minValue = b;
		} else {
			minValue = c;
		}
	}

	return minValue;
}

float getMax(in float a, in float b, in float c)
{
	float maxValue;
	if (a > b) {
		if (a > c) {
			maxValue = a;
		} else {
			maxValue = c;
		}
	} else {
		if (b > c) {
			maxValue = b;
		} else {
			maxValue = c;
		}
	}

	return maxValue;
}

float hue2rgb(float v1, float v2, float h)
{
	if (h < 0)
		h += 1;
	if (h > 1)
		h -= 1;
	if (6 * h < 1)
		return v1 + (v2 - v1) * 6 * h;
	if (2 * h < 1)
		return v2;
	if (3 * h < 1)
		return v1 + (v2 - v1) * (0.66666 - h) * 6;
	return v1;
}

vec3 hsl2rgb(float h, float s, float l)
{
	vec3 rgb = vec3(1.0);
	if (s == 0) {
		rgb.r = l;
		rgb.g = l;
		rgb.b = l;
	} else {
		float temp1 = 0;
		float temp2 = 0;

		if (l < 0.5f) {
			temp2 = l * (1 + s);
		} else {
			temp2 = (l+s) - (s*l);
		}

		temp1 = 2 * l - temp2;

		rgb.r = hue2rgb(temp1, temp2, h+0.3333f);
		rgb.g = hue2rgb(temp1, temp2, h);
		rgb.b = hue2rgb(temp1, temp2, h-0.3333f);
	}

	return rgb;
}

// valid ndc from [-0.5:0.5]
float getSaturationFromNDC(vec2 ndc)
{
	float saturation = ndc.x + 0.5;
	return saturation;
}

// valid ndc from [-0.5:0.5]
float getLuminanceFromNDC(vec2 ndc)
{
	float luminance = ndc.y + 0.5;
	return luminance;
}

// valid ndc from [-0.5:0.5]
float getValueFromNDC(vec2 ndc)
{
	float value = ndc.y + 0.5;
	return value;
}

void main()
{
	float choosenAngle = 0;
	if (clickPos.x != -1 && clickPos.y != -1) {
		choosenAngle = getDegreeFromWindowSpace(clickPos);
		// color = vec4(1, 0, 0, 1);
		// return;
	} 
	vec3 choosenRGB = getRGBfromAngle(choosenAngle);

	vec2 ndc = getNDCFromWindowCoord(gl_FragCoord.xy);
	float angle = getDegreeFromWindowSpace(gl_FragCoord.xy);
	vec3 rgb = getRGBfromAngle(angle);
	vec2 fragModelCoord = getNDCFromWindowCoord(gl_FragCoord.xy);

	float distanceToCenter = distance(fragModelCoord, circleOrigin);

	// draw ring
	if (radius.x <= distanceToCenter && distanceToCenter <= radius.y) {
		// color = vec4(hue, 0, 0, 1.0f);
		// color = vec4(rgb, 1.0f);
		color = vec4(rgb, 1.0f);
	} else {
		color = vec4(1.0f);
	}

	// draw square
	if (-0.5 < ndc.x && ndc.x < 0.5 && -0.5 < ndc.y && ndc.y < 0.5) {
		// float luminance = getLuminanceFromNDC(ndc);
		float value = getValueFromNDC(ndc);
		float saturation = getSaturationFromNDC(ndc);
		float huePrima = choosenAngle / 60; 
		float chroma = value * saturation;
		float x = chroma * (1 - abs(mod(huePrima, 2) - 1));
		vec3 tempRGB = vec3(0);
		if (0 <= huePrima && huePrima < 1) {
			tempRGB.r = chroma;
			tempRGB.g = x;
			tempRGB.b = 0;
		} else if (1 <= huePrima && huePrima < 2) {
			tempRGB.r = x;
			tempRGB.g = chroma;
			tempRGB.b = 0;
		} else if (2 <= huePrima && huePrima < 3) {
			tempRGB.r = 0;
			tempRGB.g = chroma;
			tempRGB.b = x;
		} else if (3 <= huePrima && huePrima < 4) {
			tempRGB.r = 0;
			tempRGB.g = x;
			tempRGB.b = chroma;
		} else if (4 <= huePrima && huePrima < 5) {
			tempRGB.r = x;
			tempRGB.g = 0;
			tempRGB.b = chroma;
		} else if (5 <= huePrima && huePrima < 6) {
			tempRGB.r = chroma;
			tempRGB.g = 0;
			tempRGB.b = x;
		} else {
			tempRGB.r = 0;
			tempRGB.g = 0;
			tempRGB.b = 0;
		}

		float m = value - chroma;
		vec3 mVector = vec3(m);
		vec3 finalRGB = tempRGB + mVector;
		color = vec4(finalRGB, 1);
		// vec3 squareRGB = getRGBfromAngleSaturationLuminance(choosenAngle, saturation, luminance);
		// squareRGB = pow(squareRGB, vec3(1.0 / 1.8));
		// color = vec4(squareRGB, 1.0);
	}
}
